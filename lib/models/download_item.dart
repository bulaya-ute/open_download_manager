import 'package:open_download_manager/models/partial_download_file.dart';

import 'download_status.dart';

class DownloadItem {
  String url;
  String filename;
  DownloadStatus status;
  int? fileSize;
  int? speed;
  DateTime dateAdded;
  DateTime lastAttempt;
  double? progress; // Progress measured in range [0.0, 1.0]
  final String partialFilePath;
  void Function()? onComplete;
  void Function(double progress)? onProgress;
  int? speedLimit;
  bool isSelected = false;
  String? errorMessage;
  PartialDownloadFile? partialFileObject;

  DownloadItem({
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

  DownloadItem copyWith({DownloadStatus? status}) {
    return DownloadItem(
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
      speed: speed,
    );
  }

  void getPartialFile() async {
    partialFileObject = await PartialDownloadFile.load(partialFilePath);
  }
}
