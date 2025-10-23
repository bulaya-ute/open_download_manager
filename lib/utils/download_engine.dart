import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/active_download.dart';
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
    PartialDownloadFile partialDownloadFile, {
    void Function(int downloadedBytes)? onProgress,
    void Function()? onComplete,
    void Function(String error)? onError,
    void Function()? onPause, 
    void Function()? updateUi,
  }) async {
    final resolvedPath = File(partialDownloadFile.filePath).absolute.path;

    // Check if already exists in either list
    if (_activeDownloads.containsKey(resolvedPath) ||
        _queuedDownloads.containsKey(resolvedPath)) {
      print('Download already exists: $resolvedPath');
      return;
    }

    // Create the download with callbacks
    final download = ActiveDownload(
      partialDownloadFile,
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

    await addDownload(partialFile);
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

  // /// Resume a previously paused download (add it back to the queue)
  // static Future<void> resumeDownload(String partialFilePath) async {
  //   final resolvedPath = File(partialFilePath).absolute.path;
  //
  //   // Only add if not already in either list
  //   if (!_activeDownloads.containsKey(resolvedPath) &&
  //       !_queuedDownloads.containsKey(resolvedPath)) {
  //     await addDownload(resolvedPath);
  //   } else {
  //     print('Download already in queue or active: $resolvedPath');
  //   }
  // }

  static void print(String message) {
    debugPrint("[DL ENGINE] $message");
  }
}


