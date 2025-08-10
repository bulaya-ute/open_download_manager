import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/download_item.dart';
import '../models/app_settings.dart';

class DataService {
  static const String _downloadsFileName = 'downloads.json';
  static const String _settingsFileName = 'settings.json';

  static String? _appDirectory;

  /// Initialize data service and get app directory
  static Future<void> initialize() async {
    _appDirectory = await _getAppDirectory();
    await _ensureDirectoriesExist();
  }

  /// Get the application data directory
  static Future<String> _getAppDirectory() async {
    // For development, use a local directory
    // In production, this would be in the user's app data directory
    final currentDir = Directory.current.path;
    return path.join(currentDir, 'app_data');
  }

  /// Ensure required directories exist
  static Future<void> _ensureDirectoriesExist() async {
    if (_appDirectory == null) return;

    final appDir = Directory(_appDirectory!);
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
  }

  /// Get downloads file path
  static String get _downloadsFilePath {
    if (_appDirectory == null) throw Exception('DataService not initialized');
    return path.join(_appDirectory!, _downloadsFileName);
  }

  /// Get settings file path
  static String get _settingsFilePath {
    if (_appDirectory == null) throw Exception('DataService not initialized');
    return path.join(_appDirectory!, _settingsFileName);
  }

  /// Load downloads from file
  static Future<List<DownloadItem>> loadDownloads() async {
    try {
      final file = File(_downloadsFilePath);
      if (!await file.exists()) {
        // Create empty downloads file
        await _saveDownloadsToFile([]);
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);

      return jsonList.map((json) => DownloadItem.fromJson(json)).toList();
    } catch (e) {
      print('Error loading downloads: $e');
      return [];
    }
  }

  /// Save downloads to file
  static Future<void> saveDownloads(List<DownloadItem> downloads) async {
    await _saveDownloadsToFile(downloads);
  }

  static Future<void> _saveDownloadsToFile(List<DownloadItem> downloads) async {
    try {
      final file = File(_downloadsFilePath);
      final jsonList = downloads.map((download) => download.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving downloads: $e');
    }
  }

  /// Load app settings from file
  static Future<AppSettings> loadSettings() async {
    try {
      final file = File(_settingsFilePath);
      if (!await file.exists()) {
        // Create default settings file
        final defaultSettings = AppSettings();
        await saveSettings(defaultSettings);
        return defaultSettings;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> json = jsonDecode(jsonString);

      return AppSettings.fromJson(json);
    } catch (e) {
      print('Error loading settings: $e');
      return AppSettings();
    }
  }

  /// Save app settings to file
  static Future<void> saveSettings(AppSettings settings) async {
    try {
      final file = File(_settingsFilePath);
      final jsonString = jsonEncode(settings.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  /// Add a single download item
  static Future<void> addDownload(DownloadItem download) async {
    final downloads = await loadDownloads();
    downloads.add(download);
    await saveDownloads(downloads);
  }

  /// Update a download item
  static Future<void> updateDownload(DownloadItem updatedDownload) async {
    final downloads = await loadDownloads();
    final index = downloads.indexWhere((d) => d.id == updatedDownload.id);
    if (index != -1) {
      downloads[index] = updatedDownload;
      await saveDownloads(downloads);
    }
  }

  /// Remove a download item
  static Future<void> removeDownload(String downloadId) async {
    final downloads = await loadDownloads();
    downloads.removeWhere((d) => d.id == downloadId);
    await saveDownloads(downloads);
  }

  /// Get app data directory path for external use
  static String? get appDirectory => _appDirectory;
}
