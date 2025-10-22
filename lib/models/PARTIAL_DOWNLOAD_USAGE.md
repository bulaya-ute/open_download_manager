# Partial Download File Usage Guide

## Overview

The `PartialDownloadFile` and `PartialDownloadHeader` classes implement a resumable download file format where:
- **First 128 KB**: JSON metadata header (download state, URL, progress, etc.)
- **Remaining bytes**: Downloaded file content (payload)

This allows pausing, resuming, and tracking downloads even if the app crashes or restarts.

## Quick Start

### 1. Creating a New Download

```dart
import 'package:open_download_manager/models/partial_download_file.dart';

// Create a new partial download file
final partialFile = await PartialDownloadFile.create(
  url: 'https://example.com/file.zip',
  downloadDir: '/path/to/downloads',
  // Optional parameters - will be auto-detected if not provided:
  downloadFilename: null,  // Auto-extracted from URL or Content-Disposition
  fileSize: null,          // Auto-fetched via HEAD request
  supportsResume: null,    // Auto-checked via Accept-Ranges header
  website: 'example.com',
);

print('Created: ${partialFile.filePath}');
print('File size: ${partialFile.header.fileSize} bytes');
print('Supports resume: ${partialFile.header.supportsResume}');
```

### 2. Loading an Existing Partial Download

```dart
// Load from disk
final partialFile = await PartialDownloadFile.load('/path/to/file.odm');

print('URL: ${partialFile.header.url}');
print('Progress: ${(partialFile.progress ?? 0) * 100}%');
print('Downloaded: ${partialFile.header.downloadedBytes} bytes');
print('Resume from byte: ${partialFile.getResumeByte()}');
```

### 3. Appending Downloaded Data

```dart
import 'dart:typed_data';

// Simulate downloading chunks
final chunk = Uint8List.fromList([/* your downloaded bytes */]);

// Append to the partial file
await partialFile.appendToPayload(chunk);

print('Progress: ${(partialFile.progress ?? 0) * 100}%');
print('Speed: ${partialFile.downloadSpeed} bytes/second');
```

### 4. Extracting the Final File

```dart
// When download is complete, extract the payload
final finalFilePath = await partialFile.extractPayload(
  removePayloadFromPartialFile: true,  // Keep only header for history
  chunkSize: 1024 * 1024,              // Process in 1 MB chunks
);

print('File saved to: $finalFilePath');
```

## Complete Download Example

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:open_download_manager/models/partial_download_file.dart';

Future<void> downloadFile(String url, String downloadDir) async {
  // Step 1: Create or load partial file
  PartialDownloadFile partialFile;
  
  final existingPath = '$downloadDir/myfile.odm';
  if (await File(existingPath).exists()) {
    // Resume existing download
    partialFile = await PartialDownloadFile.load(existingPath);
    print('Resuming download from ${partialFile.header.downloadedBytes} bytes');
  } else {
    // Start new download
    partialFile = await PartialDownloadFile.create(
      url: url,
      downloadDir: downloadDir,
    );
    print('Starting new download');
  }

  // Step 2: Set up HTTP request with range header for resume
  final headers = <String, String>{};
  if (partialFile.header.supportsResume == true && 
      partialFile.header.downloadedBytes > 0) {
    headers['Range'] = 'bytes=${partialFile.header.downloadedBytes}-';
  }

  // Step 3: Download with chunking
  final request = http.Request('GET', Uri.parse(partialFile.header.url));
  headers.forEach((key, value) => request.headers[key] = value);
  
  final response = await request.send();
  
  if (response.statusCode != 200 && response.statusCode != 206) {
    throw Exception('Download failed: ${response.statusCode}');
  }

  // Step 4: Stream and save chunks
  const chunkSize = 64 * 1024; // 64 KB chunks
  final chunks = <int>[];
  
  await for (final chunk in response.stream) {
    chunks.addAll(chunk);
    
    // Save when we have enough data
    if (chunks.length >= chunkSize) {
      await partialFile.appendToPayload(Uint8List.fromList(chunks));
      
      print('Progress: ${(partialFile.progress ?? 0) * 100}%');
      print('Speed: ${partialFile.downloadSpeed.toStringAsFixed(0)} B/s');
      
      chunks.clear();
    }
  }
  
  // Save any remaining data
  if (chunks.isNotEmpty) {
    await partialFile.appendToPayload(Uint8List.fromList(chunks));
  }

  // Step 5: Extract final file
  print('Download complete! Extracting...');
  final finalPath = await partialFile.extractPayload();
  print('Saved to: $finalPath');
}
```

## Features

### Automatic Metadata Detection

When creating a new download, the system automatically:

1. **Extracts filename** from:
   - `Content-Disposition` header
   - URL path
   - Falls back to 'downloaded_file'

2. **Detects file size** from:
   - `Content-Length` header
   - Can be null if server doesn't provide it

3. **Checks resume support** from:
   - `Accept-Ranges: bytes` header
   - Used to enable/disable resume functionality

### Resume Support

```dart
// Check if resume is supported
if (partialFile.header.supportsResume == true) {
  final resumeByte = partialFile.getResumeByte();
  // Use HTTP Range header: 'Range': 'bytes=$resumeByte-'
}
```

### Progress Tracking

```dart
// Get progress as 0.0 to 1.0
final progress = partialFile.progress;  // null if file size unknown

// Get downloaded bytes
final downloaded = partialFile.header.downloadedBytes;

// Get total size
final total = partialFile.header.fileSize;  // null if unknown
```

### Speed Monitoring

```dart
// Speed is automatically calculated during appendToPayload()
final speed = partialFile.downloadSpeed;  // bytes/second

// Returns 0 if no activity in last 2 seconds
```

### Header Access

```dart
final header = partialFile.header;

print('URL: ${header.url}');
print('Filename: ${header.downloadFilename}');
print('Created: ${header.createdAt}');
print('Last attempt: ${header.lastAttempt}');
print('Completed: ${header.completed}');
```

## File Structure Details

### Header Format (128 KB)

```json
{
  "url": "https://example.com/file.zip",
  "download_filename": "file.zip",
  "website": "example.com",
  "download_dir": "/home/user/downloads",
  "file_size": 10485760,
  "downloaded_bytes": 5242880,
  "created_at": "2025-10-22T10:30:00.000Z",
  "last_attempt": "2025-10-22T10:35:00.000Z",
  "preallocated": false,
  "completed": false,
  "header_size": 131072,
  "supports_resume": true
}
```
+ null byte padding to reach 131,072 bytes (128 KB)

### Payload Section

- Starts at byte 131,072
- Contains the actual downloaded file data
- Grows as download progresses
- Can be extracted to final file when complete

## Error Handling

```dart
try {
  final partialFile = await PartialDownloadFile.load(filePath);
} on FileSystemException catch (e) {
  print('File not found or inaccessible: $e');
} catch (e) {
  print('Invalid partial download file: $e');
}

try {
  await partialFile.appendToPayload(data);
} catch (e) {
  print('Failed to write to file: $e');
  // File might be corrupted or disk full
}
```

## Best Practices

1. **Save periodically**: Don't wait to accumulate too much data in memory before calling `appendToPayload()`

2. **Handle interruptions**: Use try-catch and ensure the file is in a valid state

3. **Check disk space**: Before starting downloads, verify sufficient space

4. **Validate after resume**: After loading, verify the file still exists and is valid

5. **Clean up**: After extraction, consider keeping or deleting the partial file based on your needs

## Integration with Database

```dart
// After creating/loading a partial file, save to database
await DatabaseHelper.upsertDownload(
  partialFilePath: partialFile.filePath,
  speed: partialFile.downloadSpeed.toInt(),
  status: 'downloading',
  errorMessage: null,
);

// Load all partial files from database
final downloads = await DownloadService.loadDownloads();
for (final download in downloads) {
  final partialFile = await PartialDownloadFile.load(download.partialFilePath!);
  // Use partialFile...
}
```

## Migration Notes

The `.odm` extension is temporary and can be changed later by:
1. Updating the file extension in the `create()` method
2. All functionality remains the same
3. Consider `.partial`, `.download`, or `.tmp` as alternatives
