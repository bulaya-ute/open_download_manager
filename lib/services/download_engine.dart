import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/partial_download_file.dart';

/// Manages multiple active downloads (Singleton)
class DownloadEngine {
  // Private constructor
  DownloadEngine._();

  /// Map of file paths to active Download instances
  static final Map<String, ActiveDownload> _activeDownloads = {};

  /// Initialize the download engine
  static void init() {
    // Initialization logic if needed in the future
    print('DownloadEngine initialized');
  }

  /// Get all active downloads
  static Map<String, ActiveDownload> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  /// Add a download to the manager
  ///
  /// [partialFilePath] - Path to the partial download file
  /// [start] - If true, starts the download immediately
  static Future<void> addDownload(
    String partialFilePath, {
    bool start = true,
  }) async {
    final resolvedPath = File(partialFilePath).absolute.path;

    if (!_activeDownloads.containsKey(resolvedPath)) {
      final download = ActiveDownload(resolvedPath);
      _activeDownloads[resolvedPath] = download;
    }

    if (start) {
      await _activeDownloads[resolvedPath]!.resume();
    }
  }

  /// Create a new download and add it to active downloads
  static Future<void> downloadFile({
    required String url,
    String? downloadFilename,
    String? website,
    String? downloadDir,
    int? fileSize,
    bool preallocated = false,
    String? partialFilePath,
  }) async {
    final partialFile = await PartialDownloadFile.create(
      url: url,
      downloadFilename: downloadFilename,
      website: website,
      downloadDir: downloadDir,
      fileSize: fileSize,
      partialFilePath: partialFilePath,
    );

    await addDownload(partialFile.filePath, start: true);
  }

  /// Remove a download from active downloads
  static void removeDownload(String partialFilePath) {
    final resolvedPath = File(partialFilePath).absolute.path;
    _activeDownloads.remove(resolvedPath);
  }

  /// Get status of all active downloads
  static Map<String, Map<String, dynamic>> getStatus() {
    return _activeDownloads.map(
      (path, download) => MapEntry(path, download.getStatus()),
    );
  }

  /// Pause all active downloads
  static Future<void> pauseAll() async {
    final futures = _activeDownloads.values.map((d) => d.pause());
    await Future.wait(futures);
  }

  /// Resume all paused downloads
  static Future<void> resumeAll() async {
    final futures = _activeDownloads.values.map((d) => d.resume());
    await Future.wait(futures);
  }

  static void print(String message) {
    debugPrint("[DL ENGINE] $message");
  }
}

/// Represents a single download with pause/resume capabilities
class ActiveDownload {
  /// Path to the partial download file
  final String partialFilePath;

  /// Loaded partial download file
  late PartialDownloadFile _partialFile;

  /// Current download speed in bytes/second
  double _downloadSpeed = 0.0;

  /// Whether the download is currently active
  bool isDownloading = false;

  /// Flag to stop the download
  bool _stopFlag = false;

  /// Size of chunks to download at a time
  final int chunkSize;

  /// Download progress callback (called with downloaded bytes)
  final void Function(int downloadedBytes)? onProgress;

  /// Error callback (called with error message)
  final void Function(String error)? onError;

  /// Completion callback
  final void Function()? onComplete;

  /// HTTP client for downloads
  http.Client? _client;

  /// Stream subscription for download
  StreamSubscription? _subscription;

  ActiveDownload(
    this.partialFilePath, {
    this.chunkSize = 8192,
    this.onProgress,
    this.onError,
    this.onComplete,
  }) {
    _loadPartialFile();
  }

  /// Load the partial download file
  Future<void> _loadPartialFile() async {
    _partialFile = await PartialDownloadFile.load(partialFilePath);
  }

  /// Get current download speed with optional unit conversion
  ///
  /// [unit] - The unit to convert to: 'B', 'KB', 'MB', 'GB', or null for auto
  /// [formatted] - If true, returns a formatted string like "1.5 MB/s"
  String getDownloadSpeed({String? unit, bool formatted = false}) {
    double speed = _downloadSpeed;

    // Auto-select appropriate unit
    String selectedUnit;
    if (unit == null) {
      if (speed >= 1024 * 1024 * 1024) {
        selectedUnit = 'GB';
      } else if (speed >= 1024 * 1024) {
        selectedUnit = 'MB';
      } else if (speed >= 1024) {
        selectedUnit = 'KB';
      } else {
        selectedUnit = 'B';
      }
    } else {
      selectedUnit = unit.toUpperCase();
    }

    // Convert to selected unit
    double convertedSpeed;
    switch (selectedUnit) {
      case 'GB':
        convertedSpeed = speed / (1024 * 1024 * 1024);
        break;
      case 'MB':
        convertedSpeed = speed / (1024 * 1024);
        break;
      case 'KB':
        convertedSpeed = speed / 1024;
        break;
      case 'B':
      default:
        convertedSpeed = speed;
        break;
    }

    if (formatted) {
      return '${convertedSpeed.toStringAsFixed(2)} $selectedUnit/s';
    } else {
      return convertedSpeed.toString();
    }
  }

  /// Resume or start the download
  Future<void> resume() async {
    if (isDownloading) return;

    await _downloadThreadFunction(resume: true);
  }

  /// Pause the download
  Future<void> pause() async {
    if (!isDownloading) return;

    _stopFlag = true;

    // Cancel the subscription and client
    await _subscription?.cancel();
    _client?.close();

    print('Download paused: $partialFilePath');
  }

  /// Main download function that runs the download process
  Future<void> _downloadThreadFunction({bool resume = true}) async {
    await _loadPartialFile();

    print(
      'Starting download: ${_partialFile.header.downloadFilename}, '
      'Size: ${_partialFile.header.fileSize ?? "Unknown"} bytes',
    );

    String? errorMsg;

    try {
      // Calculate resume position
      final startOffset = _partialFile.header.downloadedBytes;

      // Set up headers for resume
      final headers = <String, String>{};
      if (startOffset > 0 &&
          resume &&
          _partialFile.header.supportsResume == true) {
        headers['Range'] = 'bytes=$startOffset-';
      }

      // Create HTTP client
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(_partialFile.header.url));
      headers.forEach((key, value) => request.headers[key] = value);

      final response = await _client!.send(request);

      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(_partialFile.header.url),
        );
      }

      // Track download speed
      final speedTracker = _SpeedTracker();
      isDownloading = true;
      _stopFlag = false;

      // Buffer for accumulating chunks
      final buffer = <int>[];

      // Listen to response stream
      _subscription = response.stream.listen(
        (chunk) async {
          if (_stopFlag) {
            _subscription?.cancel();
            _client?.close();
            isDownloading = false;
            _stopFlag = false;
            return;
          }

          buffer.addAll(chunk);

          // Write when buffer reaches chunk size
          if (buffer.length >= chunkSize) {
            await _writeChunk(Uint8List.fromList(buffer));
            speedTracker.addBytes(buffer.length);
            _downloadSpeed = speedTracker.getSpeed();

            onProgress?.call(_partialFile.header.downloadedBytes);

            buffer.clear();
          }
        },
        onDone: () async {
          // Write any remaining data
          if (buffer.isNotEmpty) {
            await _writeChunk(Uint8List.fromList(buffer));
            speedTracker.addBytes(buffer.length);
            buffer.clear();
          }

          // Download complete
          print('Download complete: ${_partialFile.header.downloadFilename}');
          await _partialFile.extractPayload(
            removePayloadFromPartialFile: false,
          );

          isDownloading = false;
          onComplete?.call();
        },
        onError: (error) {
          errorMsg = 'Stream error: $error';
          isDownloading = false;
        },
        cancelOnError: true,
      );
    } on HttpException catch (e) {
      final statusCode = int.tryParse(e.message.replaceAll('HTTP ', ''));

      if (statusCode == 403) {
        errorMsg =
            'Access forbidden (403). The URL may have expired or requires authentication.';
      } else if (statusCode == 404) {
        errorMsg =
            'File not found (404). The URL may be invalid or the file has been moved.';
      } else if (statusCode == 416) {
        errorMsg =
            'Range not satisfiable (416). The file may have changed or resume position is invalid.';
      } else if (statusCode == 429) {
        errorMsg =
            'Too many requests (429). Server is rate limiting, try again later.';
      } else if (statusCode != null && statusCode >= 500) {
        errorMsg =
            'Server error ($statusCode). The server is experiencing issues.';
      } else {
        errorMsg = 'HTTP error: $e';
      }
    } on SocketException catch (_) {
      errorMsg =
          'Connection failed. Check your internet connection or the server may be down.';
    } on TimeoutException catch (_) {
      errorMsg = 'Request timed out. The server is taking too long to respond.';
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 13) {
        errorMsg = 'Permission denied writing to file. Check file permissions.';
      } else {
        errorMsg = 'File system error: $e';
      }
    } catch (e) {
      errorMsg = 'Unexpected error: $e';
    } finally {
      isDownloading = false;

      if (errorMsg != null) {
        print('Error downloading "$partialFilePath": $errorMsg');
        onError?.call(errorMsg!);
      }

      _client?.close();
      await _subscription?.cancel();
    }
  }

  /// Write a chunk to the partial file
  Future<void> _writeChunk(Uint8List chunk) async {
    await _partialFile.appendToPayload(chunk);
  }

  /// Get current download status
  Map<String, dynamic> getStatus() {
    final downloadedBytes = _partialFile.header.downloadedBytes;
    final totalBytes = _partialFile.header.fileSize;

    double? percentage;
    String progressStr;

    if (totalBytes != null && totalBytes > 0) {
      percentage = downloadedBytes / totalBytes;
      progressStr = '${(percentage * 100).toStringAsFixed(2)}%';
    } else {
      percentage = null;
      progressStr = 'Unknown';
    }

    return {
      'downloaded_bytes': downloadedBytes,
      'total_bytes': totalBytes,
      'download_progress': progressStr,
      'status': isDownloading ? 'In progress' : 'Paused',
      'download_percentage': percentage,
      'download_speed': getDownloadSpeed(formatted: true),
      'supports_resume': _partialFile.header.supportsResume ?? 'Unknown',
      'filename': _partialFile.header.downloadFilename,
      'url': _partialFile.header.url,
    };
  }
}

/// Helper class to track download speed
class _SpeedTracker {
  final List<_SpeedSample> _samples = [];
  static const _windowDuration = Duration(seconds: 1);

  void addBytes(int bytes) {
    _samples.add(_SpeedSample(DateTime.now(), bytes));
    _cleanOldSamples();
  }

  void _cleanOldSamples() {
    final cutoff = DateTime.now().subtract(_windowDuration);
    _samples.removeWhere((sample) => sample.timestamp.isBefore(cutoff));
  }

  double getSpeed() {
    _cleanOldSamples();

    if (_samples.isEmpty) return 0.0;

    final totalBytes = _samples.fold<int>(
      0,
      (sum, sample) => sum + sample.bytes,
    );
    return totalBytes
        .toDouble(); // Already bytes per second since window is 1 second
  }
}

class _SpeedSample {
  final DateTime timestamp;
  final int bytes;

  _SpeedSample(this.timestamp, this.bytes);
}
