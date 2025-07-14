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
}

enum DownloadStatus {
  completed,
  downloading,
  failed,
  paused,
}
