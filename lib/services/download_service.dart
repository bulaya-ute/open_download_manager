import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/download_item.dart';
import '../models/app_settings.dart';
import 'odm_file_manager.dart';
import 'data_service.dart';

class DownloadService {
  static final Map<String, StreamController<DownloadItem>> _downloadStreams =
      {};
  static final Map<String, bool> _pausedDownloads = {};
  static final Map<String, int> _retryAttempts = {};
  static int _activeDownloads = 0;
  static AppSettings? _settings;

  // Configuration constants
  static const int _chunkSize = 131072; // 128KB chunks
  static const int _maxRetryAttempts = 3; // Maximum retry attempts
  static const int _retryDelaySeconds = 1; // Initial retry delay

  /// Initialize download service
  static Future<void> initialize() async {
    _settings = await DataService.loadSettings();
  }

  /// Start a download
  static Future<void> startDownload(DownloadItem downloadItem) async {
    if (_settings == null) await initialize();

    // Check if we've reached max simultaneous downloads
    if (_activeDownloads >= (_settings?.maxSimultaneousDownloads ?? 4)) {
      // Queue the download
      await _queueDownload(downloadItem);
      return;
    }

    _activeDownloads++;

    final controller = StreamController<DownloadItem>();
    _downloadStreams[downloadItem.id] = controller;

    // Initialize retry counter
    _retryAttempts[downloadItem.id] = 0;

    try {
      await _performDownloadWithRetry(downloadItem, controller);
    } catch (e) {
      print('Download failed after all retries: $e');
      await _updateDownloadStatus(
        downloadItem,
        DownloadStatus.failed,
        errorMessage: e.toString(),
      );
    } finally {
      _activeDownloads--;
      _downloadStreams.remove(downloadItem.id);
      _retryAttempts.remove(downloadItem.id);
      controller.close();

      // Start next queued download
      await _startNextQueuedDownload();
    }
  }

  /// Perform download with retry logic
  static Future<void> _performDownloadWithRetry(
    DownloadItem downloadItem,
    StreamController<DownloadItem> controller,
  ) async {
    while (_retryAttempts[downloadItem.id]! <= _maxRetryAttempts) {
      try {
        await _performDownload(downloadItem, controller);
        return; // Success, exit retry loop
      } catch (e) {
        _retryAttempts[downloadItem.id] = _retryAttempts[downloadItem.id]! + 1;

        if (_retryAttempts[downloadItem.id]! > _maxRetryAttempts) {
          throw e; // Max retries exceeded, rethrow error
        }

        // Calculate exponential backoff delay
        final delaySeconds =
            _retryDelaySeconds * (1 << (_retryAttempts[downloadItem.id]! - 1));
        print(
          'Download attempt ${_retryAttempts[downloadItem.id]} failed for ${downloadItem.filename}. Retrying in ${delaySeconds}s: $e',
        );

        // Update status to show retry
        await _updateDownloadStatus(
          downloadItem,
          DownloadStatus.downloading,
          errorMessage:
              'Retrying in ${delaySeconds}s... (attempt ${_retryAttempts[downloadItem.id]}/$_maxRetryAttempts)',
        );

        // Wait before retry with exponential backoff
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// Pause a download
  static void pauseDownload(String downloadId) {
    _pausedDownloads[downloadId] = true;
  }

  /// Resume a download
  static Future<void> resumeDownload(DownloadItem downloadItem) async {
    _pausedDownloads.remove(downloadItem.id);
    await startDownload(downloadItem);
  }

  /// Cancel a download
  static void cancelDownload(String downloadId) {
    _pausedDownloads[downloadId] = true;
    _downloadStreams[downloadId]?.close();
    _downloadStreams.remove(downloadId);
  }

  /// Get download stream for progress updates
  static Stream<DownloadItem>? getDownloadStream(String downloadId) {
    return _downloadStreams[downloadId]?.stream;
  }

  /// Perform the actual download
  static Future<void> _performDownload(
    DownloadItem downloadItem,
    StreamController<DownloadItem> controller,
  ) async {
    try {
      // Get download directory
      final downloadDir = _settings?.defaultDownloadLocation ?? 'Downloads';
      final downloadPath = path.join(downloadDir, downloadItem.filename);
      final odmPath = '$downloadPath.odm';

      // Check if final file already exists (not ODM file)
      final finalFile = File(downloadPath);
      if (await finalFile.exists()) {
        // For now, just overwrite (as requested)
        // TODO: Add dialog options for rename/overwrite/cancel in future iterations
        await finalFile.delete();
      }

      // Check if ODM file exists (resume download)
      ODMFile? existingODM;
      int startByte = 0;

      final odmFile = File(odmPath);
      if (await odmFile.exists()) {
        existingODM = await ODMFile.readODMFile(odmPath);
        if (existingODM != null) {
          startByte = existingODM.metadata.downloadedSize;
        }
      }

      // Create HTTP client and request
      final client = http.Client();
      final uri = Uri.parse(downloadItem.url);

      // Create request with Range header for resume capability
      final request = http.Request('GET', uri);
      if (startByte > 0) {
        request.headers['Range'] = 'bytes=$startByte-';
      }

      final response = await client.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw Exception('HTTP ${response.statusCode}: Failed to download');
      }

      // Get total file size
      int totalSize = startByte;
      final contentLength = response.headers['content-length'];
      if (contentLength != null) {
        totalSize += int.parse(contentLength);
      }

      // Create initial ODM metadata
      final metadata = ODMMetadata(
        url: downloadItem.url,
        filename: downloadItem.filename,
        originalFilename: downloadItem.filename,
        totalSize: totalSize,
        downloadedSize: startByte,
        dateAdded: DateTime.parse(downloadItem.dateAdded),
        lastResumed: DateTime.now(),
        status: DownloadStatus.downloading,
      );

      // Initialize ODM file if it doesn't exist
      if (existingODM == null) {
        await ODMFile.writeODMFile(odmPath, metadata, Uint8List(0));
      }

      // Download in chunks
      final chunks = <int>[];
      int downloadedBytes = startByte;

      await for (final chunk in response.stream) {
        // Check if download is paused
        if (_pausedDownloads[downloadItem.id] == true) {
          await _updateDownloadStatus(downloadItem, DownloadStatus.paused);
          break;
        }

        chunks.addAll(chunk);
        downloadedBytes += chunk.length;

        // Write to ODM file when we reach the chunk size (128KB) or at the end
        if (chunks.length >= _chunkSize || downloadedBytes >= totalSize) {
          await ODMFile.appendToODMFile(odmPath, Uint8List.fromList(chunks));
          chunks.clear();
        }

        // Update progress
        final progress = totalSize > 0 ? downloadedBytes / totalSize : 0.0;
        final updatedItem = downloadItem.copyWith(
          progress: progress,
          status: DownloadStatus.downloading,
        );

        controller.add(updatedItem);
        await DataService.updateDownload(updatedItem);

        // Apply speed limit if enabled
        if (_settings?.downloadSpeedLimit == true) {
          await _applySpeedLimit(chunk.length);
        }
      }

      client.close();

      // Check if download completed
      if (downloadedBytes >= totalSize &&
          _pausedDownloads[downloadItem.id] != true) {
        // Finalize download - convert ODM to actual file
        final success = await ODMFile.finalizeDownload(odmPath, downloadPath);

        if (success) {
          final completedItem = downloadItem.copyWith(
            progress: 1.0,
            status: DownloadStatus.completed,
            speed: '0 MB/s',
          );

          controller.add(completedItem);
          await DataService.updateDownload(completedItem);
        } else {
          throw Exception('Failed to finalize download');
        }
      }
    } catch (e) {
      final failedItem = downloadItem.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
        speed: '0 MB/s',
      );

      controller.add(failedItem);
      await DataService.updateDownload(failedItem);
    }
  }

  /// Apply speed limit delay
  static Future<void> _applySpeedLimit(int bytesDownloaded) async {
    if (_settings?.downloadSpeedLimit != true) return;

    final limitValue = _settings!.speedLimitValue;
    final limitUnit = _settings!.speedLimitUnit;

    // Convert to bytes per second
    double bytesPerSecond = limitValue;
    if (limitUnit == 'KB/s') {
      bytesPerSecond *= 1024;
    } else if (limitUnit == 'MB/s') {
      bytesPerSecond *= 1024 * 1024;
    }

    // Calculate delay needed
    final timeForBytes =
        (bytesDownloaded / bytesPerSecond) * 1000; // milliseconds
    final delay = timeForBytes.round();

    if (delay > 0) {
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  /// Update download status
  static Future<void> _updateDownloadStatus(
    DownloadItem item,
    DownloadStatus status, {
    String? errorMessage,
  }) async {
    final updatedItem = item.copyWith(
      status: status,
      errorMessage: errorMessage,
    );
    await DataService.updateDownload(updatedItem);
  }

  /// Queue download for later
  static Future<void> _queueDownload(DownloadItem downloadItem) async {
    // For now, just update status to queued (you could implement a proper queue)
    final queuedItem = downloadItem.copyWith(status: DownloadStatus.paused);
    await DataService.updateDownload(queuedItem);
  }

  /// Start next queued download
  static Future<void> _startNextQueuedDownload() async {
    // This would implement queue management
    // For now, it's a placeholder
  }
}
