import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:open_download_manager/models/partial_download_file.dart';

/// Represents a single download with pause/resume capabilities
class ActiveDownload {
  // /// Path to the partial download file
  // final String partialFilePath;

  /// Loaded partial download file
  final PartialDownloadFile partialFileObject;

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
      this.partialFileObject, {
        this.chunkSize = 8192,
        this.onProgress,
        this.onError,
        this.onComplete,
        this.onPause,
        this.updateUi,
      }) {
    // _loadPartialFile();
  }

  // /// Load the partial download file
  // Future<void> _loadPartialFile() async {
  //   partialFileObject = await PartialDownloadFile.load(partialFilePath);
  // }

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

    print('Download paused: ${partialFileObject.filePath}');

    // Notify that download was paused
    onPause?.call();
  }

  /// Main download function that runs the download process
  Future<void> _downloadThreadFunction({bool resume = true}) async {
    print(
      'Starting download: ${partialFileObject.header.downloadFilename}, '
          'Size: ${partialFileObject.header.fileSize ?? "Unknown"} bytes',
    );

    String? errorMsg;

    try {
      // Calculate resume position
      final startOffset = partialFileObject.header.downloadedBytes;

      // Set up headers for resume
      final headers = <String, String>{};
      if (startOffset > 0 &&
          resume &&
          partialFileObject.header.supportsResume == true) {
        headers['Range'] = 'bytes=$startOffset-';
      }

      // Create HTTP client
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(partialFileObject.header.url));
      headers.forEach((key, value) => request.headers[key] = value);

      final response = await _client!.send(request);

      print("Here1");
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(partialFileObject.header.url),
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

        // print("Downloaded ${(_partialFile!.header.downloadedBytes/_partialFile!.header.fileSize!).toStringAsFixed(2)}");

        // Write chunk to partial file
        await _writeChunk(Uint8List.fromList(chunk));

        // Track speed and progress
        speedTracker.addBytes(chunk.length);
        _downloadSpeed = speedTracker.getSpeed();

        // Call progress callback
        onProgress?.call(partialFileObject.header.downloadedBytes);
      }

      // Check if download completed successfully (not stopped by user)
      if (!_stopFlag && isDownloading) {
        // Download complete
        print('Download complete: ${partialFileObject.header.downloadFilename}');
        await partialFileObject.extractPayload(
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
        print('Error downloading "${partialFileObject.header.downloadFilename}": $errorMsg');
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
    // partialFileObject.downloadSpeed = getDownloadSpeed();
    await partialFileObject.appendToPayload(chunk);
  }

  /// Get current download status
  Map<String, dynamic> getStatus() {
    // Return loading status if partial file not yet loaded

    final downloadedBytes = partialFileObject.header.downloadedBytes;
    final totalBytes = partialFileObject.header.fileSize;

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
      'supports_resume': partialFileObject.header.supportsResume ?? 'Unknown',
      'filename': partialFileObject.header.downloadFilename,
      'url': partialFileObject.header.url,
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
