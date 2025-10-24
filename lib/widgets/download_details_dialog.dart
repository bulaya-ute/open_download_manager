import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/download_item.dart';
import '../models/download_status.dart';

class DownloadDetailsDialog extends StatelessWidget {
  final DownloadItem download;

  const DownloadDetailsDialog({
    super.key,
    required this.download,
  });

  @override
  Widget build(BuildContext context) {
    final partialFile = download.partialFileObject;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Download Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Filename
                    _buildDetailRow(
                      icon: Icons.insert_drive_file,
                      label: 'Filename',
                      value: download.filename,
                      copyable: true,
                    ),
                    const Divider(height: 24),

                    // URL
                    _buildDetailRow(
                      icon: Icons.link,
                      label: 'URL',
                      value: download.url,
                      copyable: true,
                    ),
                    const Divider(height: 24),

                    // Status
                    _buildDetailRow(
                      icon: Icons.info,
                      label: 'Status',
                      value: _getStatusText(download.status),
                      valueColor: _getStatusColor(download.status),
                    ),
                    const Divider(height: 24),

                    // File Size
                    _buildDetailRow(
                      icon: Icons.storage,
                      label: 'File Size',
                      value: partialFile?.getFormattedFileSize() ?? 'Unknown',
                    ),
                    const Divider(height: 24),

                    // Downloaded
                    _buildDetailRow(
                      icon: Icons.download,
                      label: 'Downloaded',
                      value: _formatBytes(download.downloadedBytes),
                    ),
                    const Divider(height: 24),

                    // Progress
                    _buildProgressRow(download),
                    const Divider(height: 24),

                    // Resume Support
                    _buildDetailRow(
                      icon: Icons.play_arrow,
                      label: 'Resume Support',
                      value: partialFile?.header.supportsResume == true
                          ? 'Yes'
                          : partialFile?.header.supportsResume == false
                              ? 'No'
                              : 'Unknown',
                      valueColor: partialFile?.header.supportsResume == true
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const Divider(height: 24),

                    // Website
                    if (partialFile?.header.website != null &&
                        partialFile!.header.website!.isNotEmpty) ...[
                      _buildDetailRow(
                        icon: Icons.public,
                        label: 'Website',
                        value: partialFile.header.website!,
                        copyable: true,
                      ),
                      const Divider(height: 24),
                    ],

                    // Download Directory
                    _buildDetailRow(
                      icon: Icons.folder,
                      label: 'Download Directory',
                      value: partialFile?.header.downloadDir ?? 'Unknown',
                      copyable: true,
                    ),
                    const Divider(height: 24),

                    // Partial File Path
                    _buildDetailRow(
                      icon: Icons.file_present,
                      label: 'Partial File Path',
                      value: download.partialFilePath,
                      copyable: true,
                    ),
                    const Divider(height: 24),

                    // Date Added
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date Added',
                      value: _formatDateTime(download.dateAdded),
                    ),
                    const Divider(height: 24),

                    // Last Attempt
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Last Attempt',
                      value: _formatDateTime(
                        partialFile?.header.lastAttempt ?? download.dateAdded,
                      ),
                    ),
                    const Divider(height: 24),

                    // Preallocated
                    _buildDetailRow(
                      icon: Icons.disc_full,
                      label: 'Preallocated',
                      value: partialFile?.header.preallocated == true
                          ? 'Yes'
                          : 'No',
                    ),
                    const Divider(height: 24),

                    // Completed
                    _buildDetailRow(
                      icon: Icons.check_circle,
                      label: 'Completed',
                      value: partialFile?.header.completed == true ? 'Yes' : 'No',
                      valueColor: partialFile?.header.completed == true
                          ? Colors.green
                          : null,
                    ),

                    // Error message if present
                    if (download.errorMessage != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        icon: Icons.error_outline,
                        label: 'Error Message',
                        value: download.errorMessage!,
                        valueColor: Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool copyable = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                child: SelectableText(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ),
              if (copyable) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                  tooltip: 'Copy to clipboard',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressRow(DownloadItem download) {
    final progress = download.getProgress();
    final progressPercent = progress != null ? (progress * 100).toStringAsFixed(1) : 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.pie_chart, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            'Progress',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progress != null ? '$progressPercent%' : 'Unknown',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              if (progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: _getStatusColor(download.status),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.error:
        return 'Error';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.stopped:
        return 'Stopped';
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.downloading:
        return Colors.blue;
      case DownloadStatus.error:
        return Colors.red;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.stopped:
        return Colors.orange;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
