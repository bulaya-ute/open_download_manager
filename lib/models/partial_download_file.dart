import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'partial_download_header.dart';

/// Manages a partial download file with metadata header and payload
/// 
/// File structure:
/// - First 128 KB: JSON metadata header (padded with null bytes)
/// - Remaining bytes: Downloaded file payload
/// 
/// This allows pausing, resuming, and tracking download progress.
class PartialDownloadFile {
  /// Header containing download metadata
  final PartialDownloadHeader header;

  /// Path to the partial download file
  final String filePath;

  /// Tracks when speed was last calculated
  DateTime? _lastSpeedCalculation;

  /// Last calculated download speed in bytes/second
  double _lastDownloadSpeed = 0.0;

  PartialDownloadFile({
    required this.header,
    required this.filePath,
  });

  /// Get the byte position where payload writing should resume
  int getResumeByte() {
    return PartialDownloadHeader.headerSize + header.downloadedBytes;
  }

  /// Calculate download progress as a percentage (0.0 to 1.0)
  /// Returns null if file size is unknown
  double? get progress {
    if (header.fileSize == null || header.fileSize == 0) {
      return null;
    }
    return header.downloadedBytes / header.fileSize!;
  }

  /// Get current download speed in bytes/second
  /// Returns 0 if no recent activity (within last 2 seconds)
  double get downloadSpeed {
    if (_lastSpeedCalculation == null) {
      return 0.0;
    }

    final secondsSinceUpdate = DateTime.now().difference(_lastSpeedCalculation!).inSeconds;
    if (secondsSinceUpdate > 2) {
      return 0.0; // Speed data is stale
    }

    return _lastDownloadSpeed;
  }

  String getFormattedDownloadSpeed({bool formatted = true, String? unit}) {
    double speed = downloadSpeed;

    // Auto-select appropriate unit
    String selectedUnit;
    if (unit == null) {
      if (speed >= 1024 * 1024 * 1024) {
        selectedUnit = 'GB';
      } else if (speed >= 1024 * 1024) {
        selectedUnit = 'MB';
      } else if (speed >= 1024) {
        selectedUnit = 'KB';
      } else {
        selectedUnit = 'B';
      }
    } else {
      selectedUnit = unit.toUpperCase();
    }

    // Convert to selected unit
    double convertedSpeed;
    switch (selectedUnit) {
      case 'GB':
        convertedSpeed = speed / (1024 * 1024 * 1024);
        break;
      case 'MB':
        convertedSpeed = speed / (1024 * 1024);
        break;
      case 'KB':
        convertedSpeed = speed / 1024;
        break;
      case 'B':
      default:
        convertedSpeed = speed;
        break;
    }

    if (formatted) {
      return '${convertedSpeed.toStringAsFixed(2)} $selectedUnit/s';
    } else {
      return convertedSpeed.toString();
    }

  }

  /// Update download speed calculation
  void _updateSpeed(int bytesWritten, Duration timeTaken) {
    if (timeTaken.inMilliseconds > 0) {
      _lastDownloadSpeed = (bytesWritten / timeTaken.inMilliseconds) * 1000;
      _lastSpeedCalculation = DateTime.now();
    }
  }

  //

  /// Update the header on disk without modifying the payload
  /// 
  /// Rewrites the first 128KB of the file with the current header data.
  /// Useful for updating metadata like lastAttempt, completed, or downloadedBytes
  /// without writing any payload data.
  Future<void> updateHeaderOnDisk() async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('Partial download file does not exist', filePath);
    }

    // Open file in read-write mode
    final raf = await file.open(mode: FileMode.writeOnlyAppend);

    try {
      // Seek to the beginning
      await raf.setPosition(0);

      // Write the header
      final headerBytes = header.toBytes(pad: true);
      await raf.writeFrom(headerBytes);

      // Flush to ensure data is written to disk
      await raf.flush();
    } finally {
      await raf.close();
    }
  }

  /// Append data to the payload and update header metadata
  /// 
  /// Writes the data to the end of the current payload and updates
  /// the header with new downloaded_bytes count and last_attempt timestamp.
  Future<void> appendToPayload(Uint8List data) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('Partial download file does not exist', filePath);
    }

    final startTime = DateTime.now();

    // Open file in append mode
    final raf = await file.open(mode: FileMode.append);

    try {
      // Seek to the resume position
      await raf.setPosition(getResumeByte());

      // Write the data
      await raf.writeFrom(data);

      // Update header metadata
      header.downloadedBytes += data.length;
      header.lastAttempt = DateTime.now();

      // Calculate speed
      final timeTaken = DateTime.now().difference(startTime);
      _updateSpeed(data.length, timeTaken);

      // Rewrite header at the beginning of the file
      final headerBytes = header.toBytes(pad: true);
      await raf.setPosition(0);
      await raf.writeFrom(headerBytes);
    } finally {
      await raf.close();
    }
  }

  /// Extract the downloaded payload to the final file
  /// 
  /// Reads the payload from the partial download file and writes it to
  /// the destination file. Handles filename conflicts by appending numbers.
  /// 
  /// [removePayloadFromPartialFile] - If true, truncates the partial file
  /// to only contain the header after extraction.
  /// 
  /// [chunkSize] - Size of chunks to read/write at a time (default 1 MB)
  /// 
  /// Returns the path to the extracted file.
  Future<String> extractPayload({
    bool removePayloadFromPartialFile = true,
    int chunkSize = 1024 * 1024, // 1 MB chunks
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('Partial download file does not exist', filePath);
    }

    // Construct output file path
    var outputPath = path.join(header.downloadDir, header.downloadFilename);

    // Handle filename conflicts
    if (await File(outputPath).exists()) {
      final dir = path.dirname(outputPath);
      final filename = path.basenameWithoutExtension(outputPath);
      final extension = path.extension(outputPath);

      int counter = 1;
      do {
        outputPath = path.join(dir, '$filename($counter)$extension');
        counter++;
      } while (await File(outputPath).exists());
    }

    // Read payload and write to output file
    final inputFile = await file.open(mode: FileMode.read);
    final outputFile = await File(outputPath).open(mode: FileMode.write);

    try {
      // Skip header to get to payload
      await inputFile.setPosition(PartialDownloadHeader.headerSize);

      int bytesRemaining = header.downloadedBytes;

      while (bytesRemaining > 0) {
        final bytesToRead = bytesRemaining < chunkSize ? bytesRemaining : chunkSize;
        final chunk = await inputFile.read(bytesToRead);

        if (chunk.isEmpty) {
          break;
        }

        await outputFile.writeFrom(chunk);
        bytesRemaining -= chunk.length;
      }

      print('Extracted payload to: $outputPath');
    } finally {
      await inputFile.close();
      await outputFile.close();
    }

    // Optionally remove payload from partial file
    if (removePayloadFromPartialFile) {
      final raf = await file.open(mode: FileMode.write);
      try {
        await raf.truncate(PartialDownloadHeader.headerSize);
        print('Removed payload from partial file: $filePath');
      } finally {
        await raf.close();
      }
    }

    return outputPath;
  }

  /// Load an existing partial download file from disk
  static Future<PartialDownloadFile> load(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    // Read header
    final raf = await file.open(mode: FileMode.read);
    try {
      final headerBytes = await raf.read(PartialDownloadHeader.headerSize);

      if (headerBytes.length < PartialDownloadHeader.headerSize) {
        throw Exception('Invalid partial download file: header too small');
      }

      final header = PartialDownloadHeader.fromBytes(Uint8List.fromList(headerBytes));

      return PartialDownloadFile(
        header: header,
        filePath: filePath,
      );
    } finally {
      await raf.close();
    }
  }

  /// Create a new partial download file
  /// 
  /// Performs a HEAD request to gather metadata if needed, then creates
  /// the file with just the header (no payload initially).
  /// 
  /// Parameters with auto-detection:
  /// - [fileSize]: If null and [autoRequestFileSize] is true, retrieved via HEAD request
  /// - [downloadFilename]: If null and [autoRequestFilename] is true, extracted from URL/headers
  /// - [supportsResume]: If null and [autoCheckResumeSupport] is true, checked via Accept-Ranges header
  static Future<PartialDownloadFile> create({
    required String url,
    String? downloadFilename,
    String? website,
    String? downloadDir,
    int? fileSize,
    bool? supportsResume,
    String? partialFilePath,
    bool autoRequestFileSize = true,
    bool autoRequestFilename = true,
    bool autoCheckResumeSupport = true,
  }) async {
    // Set default download directory
    downloadDir ??= path.join(Directory.current.path, 'downloads');
    await Directory(downloadDir).create(recursive: true);

    // Determine what needs to be fetched
    final needsHead = (fileSize == null && autoRequestFileSize) ||
        (downloadFilename == null && autoRequestFilename) ||
        (supportsResume == null && autoCheckResumeSupport);

    // Perform HEAD request if needed
    http.Response? headResponse;
    if (needsHead) {
      try {
        headResponse = await http.head(Uri.parse(url));
      } catch (e) {
        print('Warning: HEAD request failed: $e');
      }
    }

    // Extract file size
    if (fileSize == null && autoRequestFileSize && headResponse != null) {
      final contentLength = headResponse.headers['content-length'];
      if (contentLength != null) {
        fileSize = int.tryParse(contentLength);
      }
    }

    // Extract filename
    if (downloadFilename == null && autoRequestFilename) {
      downloadFilename = await _extractFilename(url, headResponse);
    }

    // Check resume support
    if (supportsResume == null && autoCheckResumeSupport && headResponse != null) {
      final acceptRanges = headResponse.headers['accept-ranges'];
      if (acceptRanges != null) {
        supportsResume = acceptRanges.toLowerCase() == 'bytes';
      }
    }

    // Default filename if still null
    downloadFilename ??= 'downloaded_file';

    // Determine partial file path
    partialFilePath ??= path.join(downloadDir, '$downloadFilename.odm');

    // Handle conflicts
    int counter = 1;
    while (await File(partialFilePath!).exists()) {
      partialFilePath = path.join(downloadDir, '$downloadFilename($counter).odm');
      counter++;
    }

    print('Creating partial download file: $partialFilePath');

    // Create header
    final now = DateTime.now();
    final header = PartialDownloadHeader(
      url: url,
      downloadFilename: downloadFilename,
      website: website,
      downloadDir: downloadDir,
      fileSize: fileSize,
      downloadedBytes: 0,
      createdAt: now,
      lastAttempt: now,
      preallocated: false,
      completed: false,
      supportsResume: supportsResume,
    );

    // Write file with header only
    final file = File(partialFilePath);
    final headerBytes = header.toBytes(pad: true);
    await file.writeAsBytes(headerBytes);

    print('Created partial download file at: $partialFilePath');

    // Load and return
    return await load(partialFilePath);
  }

  /// Extract filename from URL or Content-Disposition header
  static Future<String> _extractFilename(String url, http.Response? headResponse) async {
    String? filename;

    // Try Content-Disposition header first
    if (headResponse != null) {
      final contentDisposition = headResponse.headers['content-disposition'];
      if (contentDisposition != null) {
        // Try to extract filename from Content-Disposition
        final filenameMatch = RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (filenameMatch != null) {
          filename = filenameMatch.group(1);
        } else {
          // Try RFC 5987 encoding
          final filenameStarMatch = RegExp(r"filename\*=(?:UTF-8'')?([^;]+)").firstMatch(contentDisposition);
          if (filenameStarMatch != null) {
            filename = Uri.decodeComponent(filenameStarMatch.group(1)!);
          }
        }
      }
    }

    // Try URL path
    if (filename == null) {
      final uri = Uri.parse(url);
      filename = path.basename(uri.path);
      if (filename.isEmpty) {
        filename = null;
      }
    }

    // Default fallback
    return filename ?? 'downloaded_file';
  }

  /// Convert to a dictionary format for serialization
  Map<String, dynamic> toJson() {
    return {
      ...header.toJson(),
      'file_path': filePath,
      'progress': progress,
      'download_speed': downloadSpeed,
    };
  }

  @override
  String toString() {
    return 'PartialDownloadFile(path: $filePath, progress: ${(progress ?? 0) * 100}%, speed: ${downloadSpeed.toStringAsFixed(0)} B/s)';
  }
}
