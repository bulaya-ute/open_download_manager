import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_download_manager/screens/settings_page.dart';
import 'package:open_download_manager/utils/database_helper.dart';
import 'package:open_download_manager/utils/download_engine.dart';
import 'package:open_download_manager/utils/download_service.dart';
import 'package:open_download_manager/utils/theme/colors.dart';
import 'package:open_download_manager/widgets/add_download_dialog.dart';
import 'package:open_download_manager/widgets/download_list_widget.dart';

import '../models/download_item.dart';
import '../models/download_status.dart';

class DownloadManagerHomePage extends StatefulWidget {
  const DownloadManagerHomePage({super.key});

  @override
  State<DownloadManagerHomePage> createState() =>
      _DownloadManagerHomePageState();
}

class _DownloadManagerHomePageState extends State<DownloadManagerHomePage> {
  String _currentTab = 'all';
  final TextEditingController _searchController = TextEditingController();
  List<DownloadItem> _downloadList = DownloadService.downloadsList;
  Timer? _speedUpdateTimer;

  @override
  void initState() {
    super.initState();
    _startSpeedUpdateTimer();
  }

  @override
  void dispose() {
    _speedUpdateTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Start a timer to periodically update download speeds from the engine
  void _startSpeedUpdateTimer() {
    _speedUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Get status from download engine
      final engineStatus = DownloadEngine.getStatus();

      if (engineStatus.isEmpty) return;

      setState(() {
        for (var download in _downloadList) {
          if (download.partialFilePath != null &&
              engineStatus.containsKey(download.partialFilePath)) {
            final status = engineStatus[download.partialFilePath!];

            // Update speed if available (formatted string like "1.5 MB/s")
            if (status != null && status['download_speed'] != null) {
              // Speed is already formatted by the engine, just store for display
              // The actual numeric speed calculation is handled by the engine
            }
          }
        }
      });
    });
  }

  Future<void> refreshDownloadList() async {
    debugPrint("Refreshing list...");
    setState(() {
      _downloadList = DownloadService.downloadsList;
    });
  }

  List<DownloadItem> get _filteredDownloads {
    List<DownloadItem> filtered = _downloadList;

    // Filter by tab
    switch (_currentTab) {
      case 'completed':
        filtered = filtered
            .where((item) => item.status == DownloadStatus.completed)
            .toList();
        break;
      case 'incomplete':
        filtered = filtered
            .where(
              (item) =>
                  item.status == DownloadStatus.downloading ||
                  item.status == DownloadStatus.paused,
            )
            .toList();
        break;
      case 'failed':
        filtered = filtered
            .where((item) => item.status == DownloadStatus.error)
            .toList();
        break;
      default: // 'all'
        break;
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (item) =>
                item.filename.toLowerCase().contains(query) ||
                item.url.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  int _getTabCount(String tab) {
    switch (tab) {
      case 'all':
        return _downloadList.length;
      case 'completed':
        return _downloadList
            .where((item) => item.status == DownloadStatus.completed)
            .length;
      case 'incomplete':
        return _downloadList
            .where(
              (item) =>
                  item.status == DownloadStatus.downloading ||
                  item.status == DownloadStatus.paused,
            )
            .length;
      case 'error':
        return _downloadList
            .where((item) => item.status == DownloadStatus.error)
            .length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top toolbar and search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Toolbar buttons
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      _buildToolbarButton(
                        Icons.add,
                        'Add New Download',
                        () async {
                          await showDialog<Map<String, String>>(
                            context: context,
                            builder: (context) => AddDownloadDialog(
                              onRefreshDownloadList: refreshDownloadList,
                            ),
                          );
                          // Dialog handles everything internally now
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        Icons.play_arrow,
                        'Resume selected downloads',
                        () {
                          _resumeSelectedDownloads();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        Icons.pause,
                        'Pause selected downloads',
                        () {
                          _pauseSelectedDownloads();
                        },
                      ),
                      // const SizedBox(width: 8),
                      // _buildToolbarButton(
                      //   Icons.queue,
                      //   'Queue selected downloads',
                      //   () {
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text('Queue selected downloads')),
                      //     );
                      //   },
                      // ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(
                        Icons.delete,
                        'Delete selected downloads',
                        () {
                          _showDeleteConfirmationDialog();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildToolbarButton(Icons.settings, 'Settings', () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      }),
                      const SizedBox(width: 8),
                      _buildRefreshButton(
                        Icons.refresh,
                        'Refresh Downloads',
                        () {
                          refreshDownloadList();
                        },
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Tab navigation
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surface,
                    border: BoxBorder.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha(25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTab('all', 'All Downloads', _getTabCount('all')),
                      _buildTab(
                        'completed',
                        'Completed',
                        _getTabCount('completed'),
                      ),
                      _buildTab(
                        'incomplete',
                        'Incomplete',
                        _getTabCount('incomplete'),
                      ),
                      _buildTab('failed', 'Failed', _getTabCount('failed')),
                    ],
                  ),
                ),

                Spacer(),

                // Search field
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search downloads...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: onSurface.withAlpha(25)),
                      ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: Colors.grey[300]!),
                      // ),
                      // focusedBorder: OutlineInputBorder(
                      //   borderRadius: BorderRadius.circular(8),
                      //   borderSide: BorderSide(color: primary),
                      // ),
                      filled: false,
                      // fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
                top: 0,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DownloadListWidget(
                downloads: _filteredDownloads,
                currentTab: _currentTab,
                onRefreshDownloadList: () {
                  setState(() {});
                },
                onToggleSelection: (DownloadItem download) {
                  setState(() {
                    download.isSelected = !download.isSelected;
                  });
                },
                onSelectAll: () {
                  setState(() {
                    for (var download in _filteredDownloads) {
                      download.isSelected = true;
                    }
                  });
                },
                onDeselectAll: () {
                  setState(() {
                    for (var download in _filteredDownloads) {
                      download.isSelected = false;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tabKey, String title, int count) {
    final isActive = _currentTab == tabKey;

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tabKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.transparent,
            // border: Border.all(
            //   color: Theme.of(context).colorScheme.onSurface.withAlpha(25)
            //   ),
          ),
          child: Text(
            '$title($count)',
            style: TextStyle(
              color: isActive ? onSurface : onSurface.withAlpha(200),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildRefreshButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  void _resumeSelectedDownloads() async {
    final selectedDownloads = _downloadList.where((d) => d.isSelected).toList();

    if (selectedDownloads.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No downloads selected')));
      return;
    }

    for (final download in selectedDownloads) {
      // Skip completed downloads
      if (download.status == DownloadStatus.completed) {
        continue;
      }

      try {
        // final index = _downloads.indexWhere(
        //   (d) => d.partialFilePath == download.partialFilePath,
        // );

        // Update status to downloading in UI
        setState(() {
          download.status = DownloadStatus.downloading;
        });

        if (download.partialFileObject == null) {
          await download.loadPartialFile();
        }

        // print("Partial: ${download.partialFileObject}");
        // Add to download engine with UI update callbacks
        await DownloadEngine.addDownload(
          download.partialFileObject!,
          updateUi: () {
            setState(() {});
          },
          onProgress: (downloadedBytes) {
            // Update progress in UI
            setState(() {
              download.progress = download.getProgress();
              // download.speed = download.partialFileObject?.downloadSpeed;
            });
          },
          onComplete: () {
            // Update status to completed in UI
            setState(() {
              download.progress = 1.0;
              download.status = DownloadStatus.completed;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download completed: ${download.filename}'),
                backgroundColor: completedGreen,
              ),
            );
          },
          onError: (errorMessage) {
            // Update status to error in UI
            setState(() {
              // final index = _downloadList.indexWhere(
              //   (d) => d.partialFilePath == download.partialFilePath,
              // );
              // if (index != -1) {
              //   _downloadList[index] = _downloadList[index].copyWith(
              //     status: DownloadStatus.error,
              //   );
              //   _downloadList[index].errorMessage = errorMessage;
              // }
              setState(() {
                download.status = DownloadStatus.error;
                download.errorMessage = errorMessage;
              });
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Download error: ${download.filename}'),
                backgroundColor: downloadErrorRed,
              ),
            );
          },
          onPause: () {
            // Update status to paused in UI
            setState(() {
              // final index = _downloadList.indexWhere(
              //   (d) => d.partialFilePath == download.partialFilePath,
              // );
              // if (index != -1) {
              //   _downloadList[index] = _downloadList[index].copyWith(
              //     status: DownloadStatus.paused,
              //   );
              // }
              download.status = DownloadStatus.paused;
            });
          },
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resume ${download.filename}: $e'),
            backgroundColor: downloadErrorRed,
          ),
        );
      }
    }
  }

  void _pauseSelectedDownloads() async {
    final selectedDownloads = _downloadList.where((d) => d.isSelected).toList();

    if (selectedDownloads.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No downloads selected')));
      return;
    }

    for (final download in selectedDownloads) {
      // Skip completed downloads
      if (download.status == DownloadStatus.completed) {
        continue;
      }

      try {
        // Pause the download in the engine
        await DownloadEngine.pauseDownload(download.partialFilePath);
        // download.speed = 0;

        // Update status to paused in UI
        setState(() {
          // final index = _downloadList.indexWhere(
          //   (d) => d.partialFilePath == download.partialFilePath,
          // );
          // if (index != -1) {
          //   _downloadList[index] = download.copyWith(
          //     status: DownloadStatus.paused,
          //   );
          // }
          download.status = DownloadStatus.paused;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause ${download.filename}: $e'),
            backgroundColor: downloadErrorRed,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog() async {
    final selectedDownloads = _downloadList.where((d) => d.isSelected).toList();

    if (selectedDownloads.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No downloads selected')));
      return;
    }

    bool deleteFiles = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: warningYellow),
              const SizedBox(width: 8),
              Text(
                'Delete ${selectedDownloads.length} download${selectedDownloads.length > 1 ? 's' : ''}?',
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: deleteFiles,
                onChanged: (value) {
                  setDialogState(() {
                    deleteFiles = value ?? false;
                  });
                },
                title: const Text('Also delete files from disk'),
                subtitle: const Text(
                  'Remove the .odm partial files permanently',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorRed,
                foregroundColor: white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      _deleteSelectedDownloads(deleteFiles);
    }
  }

  void _deleteSelectedDownloads(bool deleteFiles) async {
    final selectedDownloads = _downloadList.where((d) => d.isSelected).toList();

    if (selectedDownloads.isEmpty) return;

    int successCount = 0;
    int failCount = 0;

    for (final download in selectedDownloads) {
      try {
        // Remove from database
        if (download.partialFilePath != null) {
          await DatabaseHelper.deleteDownload(download.partialFilePath!);
        }

        // Delete file from disk if requested
        if (deleteFiles && download.partialFilePath != null) {
          final file = File(download.partialFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        }

        // Remove from UI list
        setState(() {
          _downloadList.removeWhere(
            (d) => d.partialFilePath == download.partialFilePath,
          );
        });

        successCount++;
      } catch (e) {
        failCount++;
        debugPrint('Failed to delete ${download.filename}: $e');
      }
    }

    // Show result message
    if (mounted) {
      final message = successCount > 0
          ? 'Deleted $successCount download${successCount > 1 ? 's' : ''}${failCount > 0 ? ' ($failCount failed)' : ''}'
          : 'Failed to delete downloads';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failCount > 0 ? warningYellow : completedGreen,
        ),
      );
    }
  }
}
