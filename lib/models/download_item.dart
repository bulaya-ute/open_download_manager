import 'package:open_download_manager/models/partial_download_file.dart';

import 'download_status.dart';

class DownloadItem {
  // String url;
  // String filename;
  // int? fileSize;
  // int? speed;
  // DateTime dateAdded;
  // DateTime lastAttempt;
  final String partialFilePath;
  double? progress; // Progress measured in range [0.0, 1.0]
  DownloadStatus status;

  void Function()? onComplete;
  void Function(double progress)? onProgress;
  int? speedLimit;
  bool isSelected = false;
  String? errorMessage;
  PartialDownloadFile? _partialFileObject;

  int? _fileSize;
  // int _downloadedBytes;
  // String _url;



  DownloadItem({
    required this.partialFilePath,
    required this.status,
    // required this.lastAttempt,
    // required this.dateAdded,

    this.onComplete,
    this.onProgress,
    this.speedLimit,
  }) ;

  // DownloadItem copyWith({DownloadStatus? status}) {
  //   return DownloadItem(
  //     partialFilePath: partialFilePath,
  //     // url: url,
  //     // filename: filename,
  //     status: status ?? this.status,
  //     // lastAttempt: lastAttempt,
  //     // dateAdded: dateAdded,
  //     // fileSize: fileSize,
  //     // progress: progress,
  //     // onComplete: onComplete,
  //     // onProgress: onProgress,
  //     // speedLimit: speedLimit,
  //     // speed: speed,
  //   );
  // }

  Future<void> loadPartialFile() async {
    // if (_partialFileObject)
    _partialFileObject = await PartialDownloadFile.load(partialFilePath);
    if (_partialFileObject == null) throw Exception("Partial file loading failed");
  }

  PartialDownloadFile? get partialFileObject {
    return _partialFileObject;
  }

  int? get fileSize {
    if (partialFileObject != null) return partialFileObject!.header.fileSize;
    return _fileSize;
  }

  int get downloadedBytes {
    return partialFileObject!.header.downloadedBytes;
  }

  String get url {
    return partialFileObject!.header.url;
  }

  String get filename {
    return partialFileObject!.header.downloadFilename;
  }

  DateTime get dateAdded {
    return partialFileObject!.header.createdAt;
  }

  double? getProgress() {
    final int? totalBytes = fileSize;
    if (totalBytes != null && totalBytes > 0) {
      return downloadedBytes / totalBytes;
    }
    return null;
  }

  String get speed {
    return "${partialFileObject?.downloadSpeed}";
  }
}
