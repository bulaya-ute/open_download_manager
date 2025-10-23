# Database Usage Guide

## Overview
The download manager uses SQLite to persist download history. The database is stored in `app_data/downloads.db`.

## Database Schema

### Table: `downloads`
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| partialFilePath | TEXT | PRIMARY KEY | Path to the .odm partial download file |
| speed | INTEGER | NULL | Download speed in bytes/second |
| status | TEXT | NOT NULL | Download status (downloading, paused, stopped, error, completed) |
| errorMessage | TEXT | NULL | Error message if download failed |

## Usage Examples

### Loading Downloads
```dart
// Load all downloads, skipping those with missing files (default)
await DownloadService.loadDownloads();

// Load all downloads, including those with missing files
await DownloadService.loadDownloads(skipMissingFiles: false);
```

### Adding/Updating a Download
```dart
await DatabaseHelper.upsertDownload(
  partialFilePath: '/path/to/file.odm',
  speed: 1024000, // bytes/second
  status: 'downloading',
  errorMessage: null,
);
```

### Deleting a Download
```dart
await DatabaseHelper.deleteDownload('/path/to/file.odm');
```

### Getting a Specific Download
```dart
final download = await DatabaseHelper.getDownload('/path/to/file.odm');
if (download != null) {
  print('Status: ${download['status']}');
  print('Speed: ${download['speed']}');
}
```

### Clearing All Downloads
```dart
await DatabaseHelper.clearAllDownloads();
```

## Implementation Notes

1. **Partial File Headers**: Most download metadata (url, filename, fileSize, dateAdded, etc.) is stored in the partial file headers, not in the database. The database only stores the essential fields needed for persistence.

2. **File Existence Check**: The `loadDownloads()` method checks if partial files actually exist before loading them. Use `skipMissingFiles: false` to load all database records regardless.

3. **Placeholder Values**: Currently, `loadDownloads()` uses placeholder values for fields that should be read from partial file headers. You'll need to implement the logic to read these headers and populate:
   - `url`
   - `filename`
   - `fileSize`
   - `dateAdded`
   - `lastAttempt`
   - `progress`

4. **Status Enum**: The status is stored as a string in the database (e.g., "downloading", "paused") and converted to the `DownloadStatus` enum when loading.

## TODOs

- [ ] Implement partial file header reading logic
- [ ] Replace placeholder values in `loadDownloads()` with actual data from partial files
- [ ] Implement `addDownload()` to save new downloads to database
- [ ] Implement `removeDownload()` to delete downloads from database
- [ ] Add database migration support for future schema changes
