import 'package:flutter/material.dart';
import 'package:open_download_manager/services/download_service.dart';
// import '../models/download_item.dart';

class DownloadListWidget extends StatefulWidget {
  final List<Download> downloads;
  final String currentTab;
  final Function(Download) onToggleSelection;
  final Function() onSelectAll;
  final Function() onDeselectAll;
  final Future<void> Function() onRefreshDownloadList;

  const DownloadListWidget({
    super.key,
    required this.downloads,
    required this.currentTab,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onDeselectAll, 
    required this. onRefreshDownloadList,
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
              _buildColumnHeader('Status', flex: 2),
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
              print("Download $index: $download");
              // return Placeholder();
              // final row = _buildDownloadRow(download);
              final row = buildDownloadRow(download);
              return row;
            },
          ),
        ),
      ],
    );
  }

  Widget buildDownloadRow(Download download) {
        // print("here2");


    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(details.globalPosition, download);
      },
      child: Container(
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
                // widget.onToggleSelection(download);
                download.isSelected = value!;
              },
            ),
            // Filename
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  download.filename,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: _buildStatusColumn(download),
              ),
            ),
            // Size
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  "${download.fileSize}",
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
                  "${download.speed}",
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
                  "${download.dateAdded}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildDownloadRow(Download download) {
    print("here");
    return GestureDetector(
      onSecondaryTapDown: (details) {
        _showContextMenu(details.globalPosition, download);
      },
      child: Container(
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
                // widget.onToggleSelection(download);
                download.isSelected = value!;
              },
            ),
            // Filename
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  download.filename,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: _buildStatusColumn(download),
              ),
            ),
            // Size
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  "${download.fileSize}",
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
                  "${download.speed}",
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
                  "${download.dateAdded}",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
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
      case DownloadStatus.error:
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
      case DownloadStatus.stopped:
        return const Icon(
          Icons.pause_circle,
          color: Colors.orange,
          size: 20,
        );
    }
  }

  Widget _buildStatusColumn(Download download) {
    String statusText = '';
    Widget statusIcon = _getStatusIcon(download.status);
    String progress = (download.progress == null) ? "Unknown" : "${(download.progress! * 100).toInt()}%";
    
    switch (download.status) {
      case DownloadStatus.completed:
        statusText = 'Completed';
        break;
      case DownloadStatus.downloading:
        statusText = 'Downloading... $progress';
        break;
      case DownloadStatus.error:
        statusText = download.errorMessage ?? 'Failed. $progress';
        break;
      case DownloadStatus.paused:
        statusText = 'Paused. $progress';
        break;
      case DownloadStatus.stopped:
        statusText = 'Stopped. $progress';
        break;
    }
    
    return Row(
      children: [
        statusIcon,
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            statusText,
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showContextMenu(Offset position, Download download) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 30, 30),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'open',
          enabled: download.status == DownloadStatus.completed,
          child: Row(
            children: [
              Icon(
                Icons.open_in_new,
                size: 16,
                color: download.status == DownloadStatus.completed ? null : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Open',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'open_folder',
          enabled: download.status == DownloadStatus.completed,
          child: Row(
            children: [
              Icon(
                Icons.folder_open,
                size: 16,
                color: download.status == DownloadStatus.completed ? null : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Open containing folder',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'refresh_link',
          enabled: download.status == DownloadStatus.error,
          child: Row(
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: download.status == DownloadStatus.error ? null : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Refresh download link',
                style: TextStyle(
                  color: download.status == DownloadStatus.error ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'remove_list',
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline, size: 16),
              SizedBox(width: 8),
              Text('Remove from list'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete_file',
          enabled: download.status == DownloadStatus.completed,
          child: Row(
            children: [
              Icon(
                Icons.delete,
                size: 16,
                color: download.status == DownloadStatus.completed ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'rename_file',
          enabled: download.status == DownloadStatus.completed,
          child: Row(
            children: [
              Icon(
                Icons.edit,
                size: 16,
                color: download.status == DownloadStatus.completed ? null : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Rename file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'move_file',
          enabled: download.status == DownloadStatus.completed,
          child: Row(
            children: [
              Icon(
                Icons.drive_file_move,
                size: 16,
                color: download.status == DownloadStatus.completed ? null : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Move file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed ? null : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value, download);
      }
    });
  }

  void _handleContextMenuAction(String action, Download download) {
    switch (action) {
      case 'refresh_link':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Refreshing download link for ${download.filename}')),
        );
        // TODO: Implement refresh link functionality
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action action for ${download.filename}')),
        );
    }
  }
}
