import 'dart:async';
import 'dart:io';
import 'package:open_download_manager/services/gateway.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart';

class DownloadService {
  static List<Download> downloads = [];

  static Future<void> addDownload(String partialFilePath) async {}
  static Future<void> removeDownload(String partialFilePath) async {}
  
  /// Load downloads from the database
  /// 
  /// Reads all download records from the SQLite database and populates the
  /// downloads list. For each record, checks if the partial file exists.
  /// 
  /// Parameters:
  ///   - skipMissingFiles: If true (default), skips downloads whose partial
  ///     files don't exist. If false, loads all records regardless.
  /// 
  /// Returns: List of Download objects loaded from the database
  static Future<List<Download>> loadDownloads({bool skipMissingFiles = false}) async {
    final List<Download> loadedDownloads = [];
    
    try {
      // Get all download records from the database
      final records = await DatabaseHelper.getAllDownloads();
      
      for (final record in records) {
        final partialFilePath = record['partialFilePath'] as String;
        
        // Check if the file exists
        final file = File(partialFilePath);
        if (skipMissingFiles && !await file.exists()) {
          // Skip this download as the file doesn't exist
          continue;
        }
        
        // Parse status from database
        final statusString = record['status'] as String;
        final status = DownloadStatus.values.firstWhere(
          (e) => e.name == statusString,
          orElse: () => DownloadStatus.stopped,
        );
        
        // Get speed and errorMessage from database
        final speed = record['speed'] as int?;
        final errorMessage = record['errorMessage'] as String?;
        
        // TODO: Read actual metadata from partial file header
        // For now, using placeholder values
        final download = Download(
          partialFilePath: partialFilePath,
          url: 'placeholder://url', // TODO: Read from partial file
          filename: path.basename(partialFilePath).replaceAll('.odm', ''), // Placeholder
          status: status,
          dateAdded: DateTime.now(), // TODO: Read from partial file
          lastAttempt: DateTime.now(), // TODO: Read from partial file
          fileSize: null, // TODO: Read from partial file
          progress: 0.0, // TODO: Calculate from partial file
          speed: speed,
        );
        
        // Set error message if present
        if (errorMessage != null) {
          download.errorMessage = errorMessage;
        }
        
        loadedDownloads.add(download);
      }
      
      // Overwrite the downloads list
      downloads = loadedDownloads;
      
    } catch (e) {
      print('Error loading downloads from database: $e');
      // Return empty list on error
      downloads = [];
    }
    
    return downloads;
  }

  static Future<Map<String, dynamic>?> readPartialFile(
    String partialFilePath,
  ) async {
    final response = await Gateway.sendRequest(
      "GET",
      "/read-partial-file",
      queryParams: {"path": partialFilePath},
    );
    return response;
  }
}

class Download {
  String url;
  String filename;
  DownloadStatus status;
  int? fileSize;
  int? speed;
  DateTime dateAdded;
  DateTime lastAttempt;
  double? progress; // Progress measured in range [0.0, 1.0]
  final String? partialFilePath;
  void Function()? onComplete;
  void Function(double progress)? onProgress;
  int? speedLimit;
  bool isSelected = false;
  String? errorMessage;

  Download({
    required this.partialFilePath,
    required this.url,
    required this.filename,
    required this.status,
    required this.lastAttempt,
    required this.dateAdded,

    this.fileSize,
    this.progress,
    this.onComplete,
    this.onProgress,
    this.speedLimit,
    this.speed,
  });

  Download copyWith({DownloadStatus? status}) {
    return Download(
      partialFilePath: partialFilePath,
      url: url,
      filename: filename,
      status: status ?? this.status,
      lastAttempt: lastAttempt,
      dateAdded: dateAdded,
      fileSize: fileSize,
      progress: progress,
      onComplete: onComplete,
      onProgress: onProgress,
      speedLimit: speedLimit,
      speed: speed
    );
  }
}

enum DownloadStatus { downloading, paused, stopped, error, completed }
