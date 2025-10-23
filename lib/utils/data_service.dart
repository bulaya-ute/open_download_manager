// import 'dart:convert';
// import 'dart:io';
// import 'package:path/path.dart' as path;
// import '../models/download_item.dart';
// import '../models/app_settings.dart';

// class DataService {
//   /// Initialize data service
//   static Future<void> init() async {
//   }


//   /// Add a single download item
//   static Future<void> addDownload(DownloadItem download) async {
//     final downloads = await loadDownloads();
//     downloads.add(download);
//     await saveDownloads(downloads);
//   }

//   /// Update a download item
//   static Future<void> updateDownload(DownloadItem updatedDownload) async {
//     final downloads = await loadDownloads();
//     final index = downloads.indexWhere((d) => d.id == updatedDownload.id);
//     if (index != -1) {
//       downloads[index] = updatedDownload;
//       await saveDownloads(downloads);
//     }
//   }

//   /// Remove a download item
//   static Future<void> removeDownload(String downloadId) async {
//     final downloads = await loadDownloads();
//     downloads.removeWhere((d) => d.id == downloadId);
//     await saveDownloads(downloads);
//   }

//   /// Get app data directory path for external use
//   static String? get appDirectory => _appDirectory;
// }
