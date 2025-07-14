import 'package:flutter/material.dart';
import 'models/download_item.dart';
import 'widgets/download_list_widget.dart';
import 'widgets/add_download_dialog.dart';
import 'widgets/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Download Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DownloadManagerHomePage(),
    );
  }
}

class DownloadManagerHomePage extends StatefulWidget {
  const DownloadManagerHomePage({super.key});

  @override
  State<DownloadManagerHomePage> createState() => _DownloadManagerHomePageState();
}

class _DownloadManagerHomePageState extends State<DownloadManagerHomePage> {
  String _currentTab = 'all';
  final TextEditingController _searchController = TextEditingController();
  
  // Sample data
  final List<DownloadItem> _allDownloads = [
    DownloadItem(
      id: '1',
      filename: 'Project_Documentation.pdf',
      size: '2.4 MB',
      url: 'https://example.com/docs/project.pdf',
      speed: '1.2 MB/s',
      dateAdded: '2024-02-10 14:30',
      status: DownloadStatus.completed,
      progress: 1.0,
    ),
    DownloadItem(
      id: '2',
      filename: 'Software_Update.zip',
      size: '156 MB',
      url: 'https://example.com/updates/v2.0.zip',
      speed: '3.8 MB/s',
      dateAdded: '2024-02-10 15:45',
      status: DownloadStatus.downloading,
      progress: 0.76,
    ),
    DownloadItem(
      id: '3',
      filename: 'Video_Tutorial.mp4',
      size: '850 MB',
      url: 'https://example.com/tutorials/vide...',
      speed: '0 MB/s',
      dateAdded: '2024-02-10 16:20',
      status: DownloadStatus.failed,
      progress: 0.32,
      errorMessage: 'Link expired',
    ),
    DownloadItem(
      id: '4',
      filename: 'Design_Assets.zip',
      size: '45 MB',
      url: 'https://example.com/assets/design.zip',
      speed: '2.1 MB/s',
      dateAdded: '2024-02-10 16:30',
      status: DownloadStatus.paused,
      progress: 0.45,
    ),
  ];

  List<DownloadItem> get _filteredDownloads {
    List<DownloadItem> filtered = _allDownloads;
    
    // Filter by tab
    switch (_currentTab) {
      case 'completed':
        filtered = filtered.where((item) => item.status == DownloadStatus.completed).toList();
        break;
      case 'incomplete':
        filtered = filtered.where((item) => 
          item.status == DownloadStatus.downloading || 
          item.status == DownloadStatus.paused
        ).toList();
        break;
      case 'failed':
        filtered = filtered.where((item) => item.status == DownloadStatus.failed).toList();
        break;
      default: // 'all'
        break;
    }
    
    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((item) => 
        item.filename.toLowerCase().contains(query) ||
        item.url.toLowerCase().contains(query)
      ).toList();
    }
    
    return filtered;
  }

  int _getTabCount(String tab) {
    switch (tab) {
      case 'all':
        return _allDownloads.length;
      case 'completed':
        return _allDownloads.where((item) => item.status == DownloadStatus.completed).length;
      case 'incomplete':
        return _allDownloads.where((item) => 
          item.status == DownloadStatus.downloading || 
          item.status == DownloadStatus.paused
        ).length;
      case 'failed':
        return _allDownloads.where((item) => item.status == DownloadStatus.failed).length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Top toolbar and search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Toolbar buttons
                _buildToolbarButton(
                  Icons.add,
                  'Add New Download',
                  () async {
                    final result = await showDialog<Map<String, String>>(
                      context: context,
                      builder: (context) => const AddDownloadDialog(),
                    );
                    
                    if (result != null) {
                      _addNewDownload(result['url']!, result['filename']!);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  Icons.play_arrow,
                  'Resume selected downloads',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Resume selected downloads')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  Icons.pause,
                  'Pause selected downloads',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pause selected downloads')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  Icons.queue,
                  'Queue selected downloads',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Queue selected downloads')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  Icons.delete,
                  'Delete selected downloads',
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delete selected downloads')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _buildToolbarButton(
                  Icons.settings,
                  'Settings',
                  () {
                    showDialog(
                      context: context,
                      builder: (context) => const SettingsScreen(),
                    );
                  },
                ),
                const Spacer(),
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
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Tab navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab('all', 'All Downloads', _getTabCount('all')),
                _buildTab('completed', 'Completed', _getTabCount('completed')),
                _buildTab('incomplete', 'Incomplete', _getTabCount('incomplete')),
                _buildTab('failed', 'Failed', _getTabCount('failed')),
              ],
            ),
          ),
          
          // Downloads list
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DownloadListWidget(
                downloads: _filteredDownloads,
                currentTab: _currentTab,
                onToggleSelection: (download) {
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
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = tabKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          '$title($count)',
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: Colors.grey[100],
          foregroundColor: Colors.grey[700],
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  void _addNewDownload(String url, String filename) {
    final newDownload = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filename: filename,
      size: '0 MB',
      url: url,
      speed: '0 MB/s',
      dateAdded: DateTime.now().toString().substring(0, 16),
      status: DownloadStatus.downloading,
      progress: 0.0,
    );
    
    setState(() {
      _allDownloads.add(newDownload);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added download: $filename'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
