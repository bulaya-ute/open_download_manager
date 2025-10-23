import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

class Config {
  static String appDir = ".";
  static String configPath = "$appDir/app_data/settings.json";
  static bool isInitialized = false;

  static Map<String, dynamic> appDefaults = {
    "partialDownloadFileExtension": ".odm",
    "downloadDir": "~/Downloads/OpenDownloadManager",
    "maxSimultaneousDownloads": 4,
    "downloadSpeedLimit": null, // in Bytes per second
    "groupByFileType": false,
    "fileTypeGroups": {
      "Images": [
        "png", "jpeg", "jpg", "gif", "webp",
        "tiff", "bmp", "svg", "ico", "heic"
      ],
      "Videos": ["mp4", "webm", "mkv", "mov", "avi", "flv", "wmv", "3gp"],
      "Documents": [
        "pdf", "doc", "docx", "txt", "rtf", "xlsx", "xls", "csv",
        "ods", "gsheet", "odt", "log", "pages", "md", "pptx", "ppt", "key",
        "odp"
      ],
      "Audio": ["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma"],
      "Compressed": ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "iso"],
      "Program": ["exe", "dmg", "app", "bin", "sh", "bat", "apk", "xapk", "ipa"],
      "General": ["*"]  // Fallback for anything else
    },
    "language": "English",
    "theme": "System",  // Options: Light, Dark, System
    "startWithSystem": true,  // For download capturing using background daemon
    "minimizeToTray": true,
    "serverHost": "localhost",
    "serverPort": 8080,
  };

  static String? partialDownloadFileExtension;
  static String? downloadDir;
  static int? maxSimultaneousDownloads;
  static int? downloadSpeedLimit;  // In bytes per second
  static bool? groupByFileType;
  static Map<String, dynamic>? fileTypeGroups;
  static String? language;
  static String? theme;
  static bool? startWithSystem;
  static bool? minimizeToTray;
  static String? serverHost;
  static int? serverPort;

  /// Construct server url
  static String get serverUrl {
    return "http://$serverHost:$serverPort";
  }

  static Future<void> init() async {
    loadSettings();
  }

  /// Load settings from config file
  static Future<void> loadSettings() async {

    final file = File(configPath);

    if (!await file.exists()) {
      await createNewConfigFile();
    }

    final contents = await file.readAsString();
    Map<String, dynamic> json = jsonDecode(contents);

    // Populate the config variables
    partialDownloadFileExtension = json['partialDownloadFileExtension'] as String;
    downloadDir = json['downloadDir'] as String;
    maxSimultaneousDownloads = json['maxSimultaneousDownloads'] as int;
    downloadSpeedLimit = json['downloadSpeedLimit'] as int?;
    groupByFileType = json['groupByFileType'] as bool?;
    fileTypeGroups = json['fileTypeGroups'] as Map<String, dynamic>;
    language = json['language'] as String;
    theme = json['theme'] as String;
    startWithSystem = json['startWithSystem'] as bool;
    minimizeToTray = json['minimizeToTray'] as bool;
    serverHost = json["serverHost"] as String;
    serverPort = json["serverPort"] as int;

    isInitialized = true;
  }

  /// Create a new config file with default settings (overwrites if exists)
  static Future<void> createNewConfigFile() async {
    final file = File(configPath);

    // Ensure the directory exists
    final dir = file.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    // Write defaults to file
    final jsonString = JsonEncoder.withIndent('  ').convert(appDefaults);
    await file.writeAsString(jsonString);

    print('Config file created at: $configPath');
  }

  static void print(String message) {
    debugPrint("[CONFIG] $message");
  }
}
