import 'package:flutter/material.dart';
import '../models/download_item.dart';

class DownloadListWidget extends StatefulWidget {
  final List<DownloadItem> downloads;
  final String currentTab;
  final Function(DownloadItem) onToggleSelection;
  final Function() onSelectAll;
  final Function() onDeselectAll;

  const DownloadListWidget({
    super.key,
    required this.downloads,
    required this.currentTab,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  @override
  State<DownloadListWidget> createState() => _DownloadListWidgetState();
}

class _DownloadListWidgetState extends State<DownloadListWidget> {
  String _sortColumn = 'filename';
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with checkboxes and column names
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              // Select all checkbox
              Checkbox(
                value: widget.downloads.isNotEmpty && 
                       widget.downloads.every((item) => item.isSelected),
                onChanged: (value) {
                  if (value == true) {
                    widget.onSelectAll();
                  } else {
                    widget.onDeselectAll();
                  }
                },
              ),
              // Column headers
              _buildColumnHeader('Filename', flex: 3),
              _buildColumnHeader('Size', flex: 1),
              _buildColumnHeader('URL', flex: 3),
              _buildColumnHeader('Speed', flex: 1),
              _buildColumnHeader('Date Added', flex: 2),
            ],
          ),
        ),
        // Download items list
        Expanded(
          child: ListView.builder(
            itemCount: widget.downloads.length,
            itemBuilder: (context, index) {
              final download = widget.downloads[index];
              return _buildDownloadRow(download);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColumnHeader(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumn == title.toLowerCase()) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = title.toLowerCase();
              _sortAscending = true;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _sortColumn == title.toLowerCase()
                    ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 16,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadRow(DownloadItem download) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          Checkbox(
            value: download.isSelected,
            onChanged: (value) {
              widget.onToggleSelection(download);
            },
          ),
          // Status icon and filename
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  _getStatusIcon(download.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      download.filename,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Size
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                download.size,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          // URL
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                download.url,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Speed
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                download.speed,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          // Date Added
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                download.dateAdded,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 20,
        );
      case DownloadStatus.downloading:
        return const Icon(
          Icons.download,
          color: Colors.blue,
          size: 20,
        );
      case DownloadStatus.failed:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 20,
        );
      case DownloadStatus.paused:
        return const Icon(
          Icons.pause_circle,
          color: Colors.orange,
          size: 20,
        );
    }
  }
}
