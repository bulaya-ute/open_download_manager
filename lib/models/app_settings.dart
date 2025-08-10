class AppSettings {
  final String defaultDownloadLocation;
  final int maxSimultaneousDownloads;
  final bool groupByFileType;
  final bool downloadSpeedLimit;
  final double speedLimitValue;
  final String speedLimitUnit;
  final Map<String, String> fileTypeGroups;
  final String language;
  final String theme;
  final bool startWithSystem;
  final bool minimizeToTray;

  AppSettings({
    this.defaultDownloadLocation = 'Downloads',
    this.maxSimultaneousDownloads = 4,
    this.groupByFileType = false,
    this.downloadSpeedLimit = false,
    this.speedLimitValue = 50,
    this.speedLimitUnit = 'KB/s',
    this.fileTypeGroups = const {
      'png,jpeg,jpg': 'Images',
      'mp4,webm': 'Videos',
      'pdf,doc,docx': 'Documents',
    },
    this.language = 'English',
    this.theme = 'System',
    this.startWithSystem = false,
    this.minimizeToTray = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultDownloadLocation': defaultDownloadLocation,
      'maxSimultaneousDownloads': maxSimultaneousDownloads,
      'groupByFileType': groupByFileType,
      'downloadSpeedLimit': downloadSpeedLimit,
      'speedLimitValue': speedLimitValue,
      'speedLimitUnit': speedLimitUnit,
      'fileTypeGroups': fileTypeGroups,
      'language': language,
      'theme': theme,
      'startWithSystem': startWithSystem,
      'minimizeToTray': minimizeToTray,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      defaultDownloadLocation: json['defaultDownloadLocation'] ?? 'Downloads',
      maxSimultaneousDownloads: json['maxSimultaneousDownloads'] ?? 4,
      groupByFileType: json['groupByFileType'] ?? false,
      downloadSpeedLimit: json['downloadSpeedLimit'] ?? false,
      speedLimitValue: (json['speedLimitValue'] ?? 50).toDouble(),
      speedLimitUnit: json['speedLimitUnit'] ?? 'KB/s',
      fileTypeGroups: Map<String, String>.from(json['fileTypeGroups'] ?? {}),
      language: json['language'] ?? 'English',
      theme: json['theme'] ?? 'System',
      startWithSystem: json['startWithSystem'] ?? false,
      minimizeToTray: json['minimizeToTray'] ?? false,
    );
  }

  AppSettings copyWith({
    String? defaultDownloadLocation,
    int? maxSimultaneousDownloads,
    bool? groupByFileType,
    bool? downloadSpeedLimit,
    double? speedLimitValue,
    String? speedLimitUnit,
    Map<String, String>? fileTypeGroups,
    String? language,
    String? theme,
    bool? startWithSystem,
    bool? minimizeToTray,
  }) {
    return AppSettings(
      defaultDownloadLocation:
          defaultDownloadLocation ?? this.defaultDownloadLocation,
      maxSimultaneousDownloads:
          maxSimultaneousDownloads ?? this.maxSimultaneousDownloads,
      groupByFileType: groupByFileType ?? this.groupByFileType,
      downloadSpeedLimit: downloadSpeedLimit ?? this.downloadSpeedLimit,
      speedLimitValue: speedLimitValue ?? this.speedLimitValue,
      speedLimitUnit: speedLimitUnit ?? this.speedLimitUnit,
      fileTypeGroups: fileTypeGroups ?? this.fileTypeGroups,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      startWithSystem: startWithSystem ?? this.startWithSystem,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }
}
