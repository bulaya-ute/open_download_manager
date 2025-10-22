import 'dart:convert';
import 'dart:typed_data';

/// Represents the header metadata of a partial download file
/// 
/// The header is a fixed-size (128 KB) section at the start of the file
/// containing JSON metadata about the download, padded with null bytes.
class PartialDownloadHeader {
  /// Fixed header size in bytes (128 KB)
  static const int headerSize = 128 * 1024;

  /// URL of the file being downloaded
  final String url;

  /// Final filename for the downloaded file
  final String downloadFilename;

  /// Website/domain where the file is from (optional)
  final String? website;

  /// Directory where the file will be saved
  final String downloadDir;

  /// Total size of the file in bytes (null if unknown)
  final int? fileSize;

  /// Number of bytes already downloaded
  int downloadedBytes;

  /// Timestamp when the download was created
  final DateTime createdAt;

  /// Timestamp of the last download attempt
  DateTime lastAttempt;

  /// Whether the file has been preallocated to full size
  final bool preallocated;

  /// Whether the download is completed
  bool completed;

  /// Whether the server supports resume (Range requests)
  final bool? supportsResume;

  PartialDownloadHeader({
    required this.url,
    required this.downloadFilename,
    this.website,
    required this.downloadDir,
    this.fileSize,
    this.downloadedBytes = 0,
    required this.createdAt,
    required this.lastAttempt,
    this.preallocated = false,
    this.completed = false,
    this.supportsResume,
  });

  /// Convert header to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'download_filename': downloadFilename,
      'website': website,
      'download_dir': downloadDir,
      'file_size': fileSize,
      'downloaded_bytes': downloadedBytes,
      'created_at': createdAt.toIso8601String(),
      'last_attempt': lastAttempt.toIso8601String(),
      'preallocated': preallocated,
      'completed': completed,
      'header_size': headerSize,
      'supports_resume': supportsResume,
    };
  }

  /// Create header from JSON map
  factory PartialDownloadHeader.fromJson(Map<String, dynamic> json) {
    return PartialDownloadHeader(
      url: json['url'] as String,
      downloadFilename: json['download_filename'] as String,
      website: json['website'] as String?,
      downloadDir: json['download_dir'] as String,
      fileSize: json['file_size'] as int?,
      downloadedBytes: json['downloaded_bytes'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastAttempt: DateTime.parse(json['last_attempt'] as String),
      preallocated: json['preallocated'] as bool? ?? false,
      completed: json['completed'] as bool? ?? false,
      supportsResume: json['supports_resume'] as bool?,
    );
  }

  /// Convert header to bytes with null padding to reach headerSize
  /// 
  /// [pad] - If true, pads with null bytes to headerSize. If false, returns raw JSON bytes.
  Uint8List toBytes({bool pad = true}) {
    final jsonString = jsonEncode(toJson());
    final jsonBytes = utf8.encode(jsonString);

    if (!pad) {
      return Uint8List.fromList(jsonBytes);
    }

    if (jsonBytes.length > headerSize) {
      throw Exception(
        'Header metadata too large: ${jsonBytes.length} bytes exceeds limit of $headerSize bytes',
      );
    }

    // Create padded buffer
    final paddedBytes = Uint8List(headerSize);
    paddedBytes.setRange(0, jsonBytes.length, jsonBytes);
    // Remaining bytes are already zero (null bytes)

    return paddedBytes;
  }

  /// Parse header from bytes (removes null padding automatically)
  static PartialDownloadHeader fromBytes(Uint8List bytes) {
    if (bytes.length < headerSize) {
      throw Exception(
        'Invalid header: expected at least $headerSize bytes, got ${bytes.length}',
      );
    }

    // Find the end of JSON (first null byte)
    int jsonEnd = bytes.length;
    for (int i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0) {
        jsonEnd = i;
        break;
      }
    }

    // Extract JSON bytes (without null padding)
    final jsonBytes = bytes.sublist(0, jsonEnd);
    final jsonString = utf8.decode(jsonBytes);
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    return PartialDownloadHeader.fromJson(jsonData);
  }

  /// Create a copy of this header with optional field updates
  PartialDownloadHeader copyWith({
    String? url,
    String? downloadFilename,
    String? website,
    String? downloadDir,
    int? fileSize,
    int? downloadedBytes,
    DateTime? createdAt,
    DateTime? lastAttempt,
    bool? preallocated,
    bool? completed,
    bool? supportsResume,
  }) {
    return PartialDownloadHeader(
      url: url ?? this.url,
      downloadFilename: downloadFilename ?? this.downloadFilename,
      website: website ?? this.website,
      downloadDir: downloadDir ?? this.downloadDir,
      fileSize: fileSize ?? this.fileSize,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      createdAt: createdAt ?? this.createdAt,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      preallocated: preallocated ?? this.preallocated,
      completed: completed ?? this.completed,
      supportsResume: supportsResume ?? this.supportsResume,
    );
  }

  @override
  String toString() {
    return 'PartialDownloadHeader(url: $url, filename: $downloadFilename, '
        'downloaded: $downloadedBytes/${fileSize ?? "unknown"} bytes, '
        'completed: $completed, supportsResume: $supportsResume)';
  }
}
