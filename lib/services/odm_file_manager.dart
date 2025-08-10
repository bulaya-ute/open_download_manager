import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/download_item.dart';

class ODMMetadata {
  final String url;
  final String filename;
  final String originalFilename;
  final int totalSize;
  final int downloadedSize;
  final DateTime dateAdded;
  final DateTime? lastResumed;
  final DownloadStatus status;
  final String? errorMessage;

  ODMMetadata({
    required this.url,
    required this.filename,
    required this.originalFilename,
    required this.totalSize,
    required this.downloadedSize,
    required this.dateAdded,
    this.lastResumed,
    required this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'filename': filename,
      'originalFilename': originalFilename,
      'totalSize': totalSize,
      'downloadedSize': downloadedSize,
      'dateAdded': dateAdded.toIso8601String(),
      'lastResumed': lastResumed?.toIso8601String(),
      'status': status.name,
      'errorMessage': errorMessage,
    };
  }

  factory ODMMetadata.fromJson(Map<String, dynamic> json) {
    return ODMMetadata(
      url: json['url'],
      filename: json['filename'],
      originalFilename: json['originalFilename'],
      totalSize: json['totalSize'],
      downloadedSize: json['downloadedSize'],
      dateAdded: DateTime.parse(json['dateAdded']),
      lastResumed: json['lastResumed'] != null
          ? DateTime.parse(json['lastResumed'])
          : null,
      status: DownloadStatus.values.firstWhere((e) => e.name == json['status']),
      errorMessage: json['errorMessage'],
    );
  }

  double get progress => totalSize > 0 ? downloadedSize / totalSize : 0.0;
}

class ODMFile {
  static const String _headerMarker = 'ODM_HEADER_START';
  static const String _headerEndMarker = 'ODM_HEADER_END';
  static const String _payloadMarker = 'ODM_PAYLOAD_START';

  final ODMMetadata metadata;
  final Uint8List payload;

  ODMFile({required this.metadata, required this.payload});

  /// Write ODM file to disk
  static Future<void> writeODMFile(
    String filePath,
    ODMMetadata metadata,
    Uint8List payload,
  ) async {
    final file = File(filePath);
    final sink = file.openWrite();

    try {
      // Write header marker
      sink.write(_headerMarker);
      sink.write('\n');

      // Write metadata as JSON
      final metadataJson = jsonEncode(metadata.toJson());
      sink.write(metadataJson);
      sink.write('\n');

      // Write header end marker
      sink.write(_headerEndMarker);
      sink.write('\n');

      // Write payload marker
      sink.write(_payloadMarker);
      sink.write('\n');

      // Write payload
      sink.add(payload);

      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  /// Read ODM file from disk
  static Future<ODMFile?> readODMFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final content = String.fromCharCodes(bytes);

      // Find header markers
      final headerStart = content.indexOf(_headerMarker);
      final headerEnd = content.indexOf(_headerEndMarker);
      final payloadStart = content.indexOf(_payloadMarker);

      if (headerStart == -1 || headerEnd == -1 || payloadStart == -1) {
        return null; // Invalid ODM file
      }

      // Extract metadata JSON
      final metadataStart =
          headerStart + _headerMarker.length + 1; // +1 for newline
      final metadataJson = content.substring(metadataStart, headerEnd);
      final metadata = ODMMetadata.fromJson(jsonDecode(metadataJson));

      // Extract payload
      final payloadDataStart =
          payloadStart + _payloadMarker.length + 1; // +1 for newline
      final payloadBytes = bytes.sublist(payloadDataStart);

      return ODMFile(
        metadata: metadata,
        payload: Uint8List.fromList(payloadBytes),
      );
    } catch (e) {
      print('Error reading ODM file: $e');
      return null;
    }
  }

  /// Update existing ODM file with new data
  static Future<void> appendToODMFile(
    String filePath,
    Uint8List newData,
  ) async {
    try {
      final existingODM = await readODMFile(filePath);
      if (existingODM == null) return;

      // Combine existing payload with new data
      final combinedPayload = Uint8List.fromList([
        ...existingODM.payload,
        ...newData,
      ]);

      // Update metadata
      final updatedMetadata = ODMMetadata(
        url: existingODM.metadata.url,
        filename: existingODM.metadata.filename,
        originalFilename: existingODM.metadata.originalFilename,
        totalSize: existingODM.metadata.totalSize,
        downloadedSize: combinedPayload.length,
        dateAdded: existingODM.metadata.dateAdded,
        lastResumed: DateTime.now(),
        status: combinedPayload.length >= existingODM.metadata.totalSize
            ? DownloadStatus.completed
            : DownloadStatus.downloading,
        errorMessage: existingODM.metadata.errorMessage,
      );

      // Write updated ODM file
      await writeODMFile(filePath, updatedMetadata, combinedPayload);
    } catch (e) {
      print('Error appending to ODM file: $e');
    }
  }

  /// Convert completed ODM file to final downloaded file
  static Future<bool> finalizeDownload(
    String odmFilePath,
    String destinationPath,
  ) async {
    try {
      final odmFile = await readODMFile(odmFilePath);
      if (odmFile == null) return false;

      // Write payload to final file
      final destinationFile = File(destinationPath);
      await destinationFile.writeAsBytes(odmFile.payload);

      // Delete ODM file
      await File(odmFilePath).delete();

      return true;
    } catch (e) {
      print('Error finalizing download: $e');
      return false;
    }
  }
}
