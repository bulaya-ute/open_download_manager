class DownloadItem {
  final String id;
  final String filename;
  final String size;
  final String url;
  final String speed;
  final String dateAdded;
  final DownloadStatus status;
  final double progress; // Progress percentage (0.0 to 1.0)
  final String? errorMessage; // Error message for failed downloads
  bool isSelected;

  DownloadItem({
    required this.id,
    required this.filename,
    required this.size,
    required this.url,
    required this.speed,
    required this.dateAdded,
    required this.status,
    this.progress = 0.0,
    this.errorMessage,
    this.isSelected = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filename': filename,
      'size': size,
      'url': url,
      'speed': speed,
      'dateAdded': dateAdded,
      'status': status.name,
      'progress': progress,
      'errorMessage': errorMessage,
      'isSelected': isSelected,
    };
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      filename: json['filename'],
      size: json['size'],
      url: json['url'],
      speed: json['speed'],
      dateAdded: json['dateAdded'],
      status: DownloadStatus.values.firstWhere((e) => e.name == json['status']),
      progress: (json['progress'] ?? 0.0).toDouble(),
      errorMessage: json['errorMessage'],
      isSelected: json['isSelected'] ?? false,
    );
  }

  DownloadItem copyWith({
    String? id,
    String? filename,
    String? size,
    String? url,
    String? speed,
    String? dateAdded,
    DownloadStatus? status,
    double? progress,
    String? errorMessage,
    bool? isSelected,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      filename: filename ?? this.filename,
      size: size ?? this.size,
      url: url ?? this.url,
      speed: speed ?? this.speed,
      dateAdded: dateAdded ?? this.dateAdded,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

enum DownloadStatus { completed, downloading, failed, paused }
