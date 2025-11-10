import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../models/download_status.dart';
import 'download_details_dialog.dart';
import '../utils/theme/colors.dart';

class DownloadListWidget extends StatefulWidget {
  final List<DownloadItem> downloads;
  final String currentTab;
  final Function(DownloadItem) onToggleSelection;
  final Function() onSelectAll;
  final Function() onDeselectAll;
  final Function() onRefreshDownloadList;

  const DownloadListWidget({
    super.key,
    required this.downloads,
    required this.currentTab,
    required this.onToggleSelection,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onRefreshDownloadList,
  });

  @override
  State<DownloadListWidget> createState() => _DownloadListWidgetState();
}

class _DownloadListWidgetState extends State<DownloadListWidget> {
  String _sortColumn = 'filename';
  bool _sortAscending = true;

  // Fixed column widths
  static const double checkboxWidth = 48.0;
  static const double minFilenameWidth = 200.0; // Minimum width for filename
  static const double statusWidth = 250.0;
  static const double sizeWidth = 120.0;
  static const double urlWidth = 400.0;
  static const double speedWidth = 120.0;
  static const double dateWidth = 180.0;

  // Calculate minimum total width (all fixed columns + minimum filename)
  double get minTotalWidth =>
      checkboxWidth +
      minFilenameWidth +
      statusWidth +
      sizeWidth +
      urlWidth +
      speedWidth +
      dateWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if we have enough space or need horizontal scrolling
        final availableWidth = constraints.maxWidth;
        final needsScrolling = availableWidth < minTotalWidth;

        // Calculate filename column width
        final filenameWidth = needsScrolling
            ? minFilenameWidth
            : availableWidth -
                  (checkboxWidth +
                      statusWidth +
                      sizeWidth +
                      urlWidth +
                      speedWidth +
                      dateWidth);

        final content = Column(
          children: [
            // Header with checkboxes and column names
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Select all checkbox
                  SizedBox(
                    width: checkboxWidth,
                    child: Checkbox(
                      value:
                          widget.downloads.isNotEmpty &&
                          widget.downloads.every((item) => item.isSelected),
                      onChanged: (value) {
                        if (value == true) {
                          widget.onSelectAll();
                        } else {
                          widget.onDeselectAll();
                        }
                      },
                    ),
                  ),
                  // Column headers
                  _buildColumnHeader(
                    'Filename',
                    width: filenameWidth,
                    isFlexible: !needsScrolling,
                  ),
                  _buildColumnHeader(
                    'Status',
                    width: statusWidth,
                    isFlexible: false,
                  ),
                  _buildColumnHeader(
                    'Size',
                    width: sizeWidth,
                    isFlexible: false,
                  ),
                  _buildColumnHeader('URL', width: urlWidth, isFlexible: false),
                  _buildColumnHeader(
                    'Speed',
                    width: speedWidth,
                    isFlexible: false,
                  ),
                  _buildColumnHeader(
                    'Date Added',
                    width: dateWidth,
                    isFlexible: false,
                  ),
                ],
              ),
            ),
            // Download items list
            Expanded(
              child: ListView.builder(
                itemCount: widget.downloads.length,
                itemBuilder: (context, index) {
                  final download = widget.downloads[index];
                  return DownloadRow(
                    download: download,
                    onRefreshDownloadList: widget.onRefreshDownloadList,
                    filenameWidth: filenameWidth,
                    isFilenameFlexible: !needsScrolling,
                    statusWidth: statusWidth,
                    checkboxWidth: checkboxWidth,
                    sizeWidth: sizeWidth,
                    urlWidth: urlWidth,
                    speedWidth: speedWidth,
                    dateWidth: dateWidth,
                  );
                },
              ),
            ),
          ],
        );

        // Wrap in horizontal scroll view if needed
        if (needsScrolling) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: minTotalWidth, child: content),
          );
        } else {
          return content;
        }
      },
    );
  }

  Widget _buildColumnHeader(
    String title, {
    required double width,
    required bool isFlexible,
  }) {
    final headerContent = InkWell(
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(width: 4),
            Icon(
              _sortColumn == title.toLowerCase()
                  ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : Icons.unfold_more,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );

    if (isFlexible) {
      return Expanded(child: headerContent);
    } else {
      return SizedBox(width: width, child: headerContent);
    }
  }
}

class DownloadRow extends StatelessWidget {
  final DownloadItem download;
  final Function() onRefreshDownloadList;
  final double filenameWidth;
  final bool isFilenameFlexible;
  final double statusWidth;
  final double checkboxWidth;
  final double sizeWidth;
  final double urlWidth;
  final double speedWidth;
  final double dateWidth;

  const DownloadRow({
    super.key,
    required this.download,
    required this.onRefreshDownloadList,
    required this.filenameWidth,
    required this.isFilenameFlexible,
    required this.statusWidth,
    required this.checkboxWidth,
    required this.sizeWidth,
    required this.urlWidth,
    required this.speedWidth,
    required this.dateWidth,
  });

  Widget _buildStatusColumn(DownloadItem download, BuildContext context) {
    String statusText = '';
    Widget statusIcon = download.getStatusIcon(context);
    double progressValue = (download.progress == null)
        ? 0.0
        : download.progress!;

    String progressString = (download.progress == null)
        ? ""
        : "${(progressValue * 100).toInt()}%";

    switch (download.status) {
      case DownloadStatus.completed:
        statusText = 'Completed';
        break;
      case DownloadStatus.downloading:
        statusText = 'Downloading...';
        break;
      case DownloadStatus.error:
        statusText = download.errorMessage ?? 'Failed';
        break;
      case DownloadStatus.paused:
        statusText = 'Paused';
        break;
      case DownloadStatus.stopped:
        statusText = 'Stopped';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            statusIcon,
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(progressString),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progressValue,
                color: download.getStatusColor(context),
                backgroundColor: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleContextMenuAction(
    String action,
    DownloadItem download,
    BuildContext context,
  ) {
    switch (action) {
      case 'refresh_link':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refreshing download link for ${download.filename}'),
          ),
        );
        // TODO: Implement refresh link functionality
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$action action for ${download.filename}')),
        );
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    DownloadItem download,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

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
                color: download.status == DownloadStatus.completed
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Open',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
                color: download.status == DownloadStatus.completed
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Open containing folder',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
                color: download.status == DownloadStatus.error
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Refresh download link',
                style: TextStyle(
                  color: download.status == DownloadStatus.error
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
                color: download.status == DownloadStatus.completed
                    ? errorRed
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Delete file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed
                      ? errorRed
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
                color: download.status == DownloadStatus.completed
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Rename file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
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
                color: download.status == DownloadStatus.completed
                    ? null
                    : Theme.of(context).colorScheme.onSurface.withAlpha(100),
              ),
              const SizedBox(width: 8),
              Text(
                'Move file',
                style: TextStyle(
                  color: download.status == DownloadStatus.completed
                      ? null
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
              ),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        _handleContextMenuAction(value, download, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    {
      return GestureDetector(
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition, download);
        },
        onDoubleTap: () {
          showDialog(
            context: context,
            builder: (context) => DownloadDetailsDialog(download: download),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: checkboxWidth,
                child: Checkbox(
                  value: download.isSelected,
                  onChanged: (value) {
                    // widget.onToggleSelection(download);
                    download.isSelected = value!;
                    onRefreshDownloadList();
                  },
                ),
              ),

              // Filename (flexible or fixed width)
              isFilenameFlexible
                  ? Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Text(
                          download.filename,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: filenameWidth,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        child: Text(
                          download.filename,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

              // Status
              SizedBox(
                width: statusWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    // vertical: 8,
                  ),
                  child: _buildStatusColumn(download, context),
                ),
              ),

              // Size
              SizedBox(
                width: sizeWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    // vertical: 12,
                  ),
                  child: Text(
                    download.partialFileObject!.getFormattedFileSize(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

              // URL
              SizedBox(
                width: urlWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    // vertical: 12,
                  ),
                  child: Text(
                    download.url,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Speed
              SizedBox(
                width: speedWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    // vertical: 12,
                  ),
                  child: Text(
                    download.status != DownloadStatus.downloading
                        ? " "
                        : download.partialFileObject!
                              .getFormattedDownloadSpeed(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

              // Date Added
              SizedBox(
                width: dateWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
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
  }
}
