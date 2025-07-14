class DownloadItem {
  final String id;
  final String filename;
  final String size;
  final String url;
  final String speed;
  final String dateAdded;
  final DownloadStatus status;
  bool isSelected;

  DownloadItem({
    required this.id,
    required this.filename,
    required this.size,
    required this.url,
    required this.speed,
    required this.dateAdded,
    required this.status,
    this.isSelected = false,
  });
}

enum DownloadStatus {
  completed,
  downloading,
  failed,
  paused,
}
