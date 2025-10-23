import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/partial_download_file.dart';
import 'config.dart';

/// Manages multiple active downloads (Singleton)
class DownloadEngine {
  // Private constructor
  DownloadEngine._();

  /// Map of file paths to currently downloading instances (limited by Config.maxSimultaneousDownloads)
  static final Map<String, ActiveDownload> _activeDownloads = {};

  /// Queue of downloads waiting to start (FIFO)
  static final Map<String, ActiveDownload> _queuedDownloads = {};

  /// Initialize the download engine
  static void init() {
    print('DownloadEngine initialized');
  }

  /// Get all active downloads (currently downloading)
  static Map<String, ActiveDownload> get activeDownloads =>
      Map.unmodifiable(_activeDownloads);

  /// Get all queued downloads (waiting to start)
  static Map<String, ActiveDownload> get queuedDownloads =>
      Map.unmodifiable(_queuedDownloads);

  /// Get total number of downloads (active + queued)
  static int get totalDownloads =>
      _activeDownloads.length + _queuedDownloads.length;

  /// Add a download to the queue and automatically start if slots available
  ///
  /// [partialFilePath] - Path to the partial download file
  /// [onProgress] - Callback for download progress updates (called with downloaded bytes)
  /// [onComplete] - Callback when download completes successfully
  /// [onError] - Callback when download encounters an error (called with error message)
  /// [onPause] - Callback when download is paused
  static Future<void> addDownload(
    String partialFilePath, {
    void Function(int downloadedBytes)? onProgress,
    void Function()? onComplete,
    void Function(String error)? onError,
    void Function()? onPause, 
    void Function()? updateUi,
  }) async {
    final resolvedPath = File(partialFilePath).absolute.path;

    // Check if already exists in either list
    if (_activeDownloads.containsKey(resolvedPath) ||
        _queuedDownloads.containsKey(resolvedPath)) {
      print('Download already exists: $resolvedPath');
      return;
    }

    // Create the download with callbacks
    final download = ActiveDownload(
      resolvedPath,
      updateUi: updateUi,
      onProgress: onProgress,
      onComplete: () {
        onComplete?.call();
        _onDownloadComplete(resolvedPath);
      },
      onError: (error) {
        onError?.call(error);
        _onDownloadError(resolvedPath);
      },
      onPause: () {
        onPause?.call();
        _onDownloadPaused(resolvedPath);
      },
    );

    // Add to queue
    _queuedDownloads[resolvedPath] = download;
    print('Download added to queue: $resolvedPath');

    // Try to process the queue
    await _processQueue();
  }

  /// Create a new download and add it to the queue
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

    await addDownload(partialFile.filePath);
  }

  /// Process the queue - start downloads if slots are available
  static Future<void> _processQueue() async {
    final maxDownloads = Config.maxSimultaneousDownloads ?? 4;

    // Start downloads while we have slots and queued items
    while (_activeDownloads.length < maxDownloads &&
        _queuedDownloads.isNotEmpty) {
      // Get the first queued download (FIFO)
      final entry = _queuedDownloads.entries.first;
      final path = entry.key;
      final download = entry.value;

      // Move from queue to active
      _queuedDownloads.remove(path);
      _activeDownloads[path] = download;

      print(
        'Starting download from queue: $path (${_activeDownloads.length}/$maxDownloads active)',
      );

      // Start the download (don't await to allow parallel processing)
      download.resume();
    }
  }

  /// Called when a download completes successfully
  static void _onDownloadComplete(String partialFilePath) {
    print('Download completed: $partialFilePath');
    _removeFromActive(partialFilePath);
    _processQueue(); // Start next queued download
  }

  /// Called when a download encounters an error
  static void _onDownloadError(String partialFilePath) {
    print('Download error: $partialFilePath');
    _removeFromActive(partialFilePath);
    _processQueue(); // Start next queued download
  }

  /// Called when a download is paused
  static void _onDownloadPaused(String partialFilePath) {
    print('Download paused: $partialFilePath');
    _removeFromBothLists(partialFilePath);
    _processQueue(); // Start next queued download
  }

  /// Remove a download from active list
  static void _removeFromActive(String partialFilePath) {
    _activeDownloads.remove(partialFilePath);
  }

  /// Remove a download from both lists (for pause operations)
  static void _removeFromBothLists(String partialFilePath) {
    _activeDownloads.remove(partialFilePath);
    _queuedDownloads.remove(partialFilePath);
  }

  /// Pause a specific download by path
  static Future<void> pauseDownload(String partialFilePath) async {
    final resolvedPath = File(partialFilePath).absolute.path;

    // Check if it's in active downloads
    if (_activeDownloads.containsKey(resolvedPath)) {
      await _activeDownloads[resolvedPath]!.pause();
      return;
    }

    // Check if it's in queued downloads
    if (_queuedDownloads.containsKey(resolvedPath)) {
      _queuedDownloads.remove(resolvedPath);
      print('Removed from queue: $resolvedPath');
    }
  }

  /// Get status of all downloads (active + queued)
  static Map<String, Map<String, dynamic>> getStatus() {
    final status = <String, Map<String, dynamic>>{};

    // Add active downloads
    _activeDownloads.forEach((path, download) {
      status[path] = {...download.getStatus(), 'queue_status': 'downloading'};
    });

    // Add queued downloads
    _queuedDownloads.forEach((path, download) {
      status[path] = {...download.getStatus(), 'queue_status': 'queued'};
    });

    return status;
  }

  /// Pause all downloads (both active and queued) and clear both lists
  static Future<void> pauseAll() async {
    print('Pausing all downloads...');

    // Pause all active downloads
    final activeFutures = _activeDownloads.values.map((d) => d.pause());
    await Future.wait(activeFutures);

    // Clear both lists
    _activeDownloads.clear();
    _queuedDownloads.clear();

    print('All downloads paused and lists cleared');
  }

  /// Resume a previously paused download (add it back to the queue)
  static Future<void> resumeDownload(String partialFilePath) async {
    final resolvedPath = File(partialFilePath).absolute.path;

    // Only add if not already in either list
    if (!_activeDownloads.containsKey(resolvedPath) &&
        !_queuedDownloads.containsKey(resolvedPath)) {
      await addDownload(resolvedPath);
    } else {
      print('Download already in queue or active: $resolvedPath');
    }
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
  PartialDownloadFile? _partialFile;

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

  /// Pause callback (called when download is paused)
  final void Function()? onPause;

  final void Function()? updateUi;

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
    this.onPause, 
    this.updateUi,
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

    // Notify that download was paused
    onPause?.call();
  }

  /// Main download function that runs the download process
  Future<void> _downloadThreadFunction({bool resume = true}) async {
    await _loadPartialFile();
    
    // Ensure partial file is loaded
    if (_partialFile == null) {
      onError?.call('Failed to load partial file');
      return;
    }

    print(
      'Starting download: ${_partialFile!.header.downloadFilename}, '
      'Size: ${_partialFile!.header.fileSize ?? "Unknown"} bytes',
    );

    // _partialFile.downloadSpeed =

    String? errorMsg;

    try {
      // Calculate resume position
      final startOffset = _partialFile!.header.downloadedBytes;

      // Set up headers for resume
      final headers = <String, String>{};
      if (startOffset > 0 &&
          resume &&
          _partialFile!.header.supportsResume == true) {
        headers['Range'] = 'bytes=$startOffset-';
      }

      // Create HTTP client
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(_partialFile!.header.url));
      headers.forEach((key, value) => request.headers[key] = value);

      final response = await _client!.send(request);

print("Here1");
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(_partialFile!.header.url),
        );
      }
print("Here2");

      // Track download speed
      final speedTracker = _SpeedTracker();
      isDownloading = true;
      _stopFlag = false;

      print('Starting stream download...');

      // Use await for to iterate over the stream directly
      await for (var chunk in response.stream) {
        // Check if download should be stopped
        if (_stopFlag) {
          print('Download stopped by user');
          isDownloading = false;
          _stopFlag = false;
          break;
        }

        // Write chunk to partial file
        await _writeChunk(Uint8List.fromList(chunk));
        
        // Track speed and progress
        speedTracker.addBytes(chunk.length);
        _downloadSpeed = speedTracker.getSpeed();

        // Call progress callback
        onProgress?.call(_partialFile!.header.downloadedBytes);
      }

      // Check if download completed successfully (not stopped by user)
      if (!_stopFlag && isDownloading) {
        // Download complete
        print('Download complete: ${_partialFile!.header.downloadFilename}');
        await _partialFile!.extractPayload(
          removePayloadFromPartialFile: false,
        );

        isDownloading = false;
        onComplete?.call();
      }
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
        onError?.call(errorMsg);
      }

      _client?.close();
      await _subscription?.cancel();
    }
  }

  static void print(String message) {
    debugPrint("[DOWNLOAD] $message");
  }

  /// Write a chunk to the partial file
  Future<void> _writeChunk(Uint8List chunk) async {
    await _partialFile!.appendToPayload(chunk);
  }

  /// Get current download status
  Map<String, dynamic> getStatus() {
    // Return loading status if partial file not yet loaded
    if (_partialFile == null) {
      return {
        'downloaded_bytes': 0,
        'total_bytes': null,
        'download_progress': 'Loading...',
        'status': 'Initializing',
        'download_percentage': null,
        'download_speed': '0 B/s',
        'supports_resume': 'Unknown',
        'filename': 'Loading...',
        'url': partialFilePath,
      };
    }

    final downloadedBytes = _partialFile!.header.downloadedBytes;
    final totalBytes = _partialFile!.header.fileSize;

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
      'supports_resume': _partialFile!.header.supportsResume ?? 'Unknown',
      'filename': _partialFile!.header.downloadFilename,
      'url': _partialFile!.header.url,
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
