import 'dart:async';
import 'dart:io';
import 'package:open_download_manager/models/partial_download_file.dart';
import 'package:open_download_manager/utils/gateway.dart';
import 'package:path/path.dart' as path;
import '../models/download_item.dart';
import '../models/download_status.dart';
import 'database_helper.dart';

class DownloadService {
  static List<DownloadItem> downloadsList = [];

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
  static Future<List<DownloadItem>> loadDownloads({bool skipMissingFiles = false}) async {
    final List<DownloadItem> loadedDownloads = [];
    
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
        final download = DownloadItem(
          partialFilePath: partialFilePath,
          status: status,
        );
        await download.loadPartialFile();
        
        // Set error message if present
        if (errorMessage != null) {
          download.errorMessage = errorMessage;
        }
        
        loadedDownloads.add(download);
      }
      
      // Overwrite the downloads list
      downloadsList = loadedDownloads;
      
    } catch (e) {
      print('Error loading downloads from database: $e');
      // Return empty list on error
      downloadsList = [];
    }
    
    return downloadsList;
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


