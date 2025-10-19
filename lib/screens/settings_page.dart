import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
// import '../services/data_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = 'Downloads';
  late AppSettings _settings;
  bool _isLoading = true;

  // File type groupings
  List<Map<String, String>> _fileTypeGroups = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    try {
      // _settings = await DataService.loadSettings();
      _fileTypeGroups = _settings.fileTypeGroups.entries
          .map((e) => {'types': e.key, 'folder': e.value})
          .toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _settings = AppSettings();
      });
    }
  }


  Future<void> _saveSettings() async {
    try {
      // Update file type groups
      final fileTypeGroupsMap = <String, String>{};
      for (final group in _fileTypeGroups) {
        if (group['types']?.isNotEmpty == true &&
            group['folder']?.isNotEmpty == true) {
          fileTypeGroupsMap[group['types']!] = group['folder']!;
        }
      }

      final updatedSettings = _settings.copyWith(
        fileTypeGroups: fileTypeGroupsMap,
      );

      // await DataService.saveSettings(updatedSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 250,
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Settings sections
                Expanded(
                  child: ListView(
                    children: [
                      _buildSidebarItem(Icons.settings, 'General'),
                      // _bu
                      _buildSidebarItem(Icons.download, 'Downloads'),
                      _buildSidebarItem(Icons.security, 'Privacy & Security'),
                      _buildSidebarItem(Icons.tune, 'Advanced'),
                      _buildSidebarItem(Icons.info, 'About'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with search
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedSection,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 250,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search settings',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(),
                  ),
                ),
                // Footer buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title) {
    final isSelected = _selectedSection == title;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            _selectedSection = title;
          });
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedSection) {
      case 'Downloads':
        return _buildDownloadsContent();
      case 'General':
        return _buildGeneralContent();
      case 'Privacy & Security':
        return _buildPrivacyContent();
      case 'Advanced':
        return _buildAdvancedContent();
      case 'About':
        return _buildAboutContent();
      default:
        return _buildDownloadsContent();
    }
  }

  Widget _buildDownloadsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Default Download Location
        _buildSettingSection(
          'Default Download Location',
          '',
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.grey),
              const SizedBox(width: 8),
              Text(_settings.defaultDownloadLocation),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder picker coming soon')),
                  );
                },
                child: const Text('Browse'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _settings = _settings.copyWith(
                      defaultDownloadLocation: 'Downloads',
                    );
                  });
                },
                child: const Text('Reset to default'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Maximum Simultaneous Downloads
        _buildSettingSection(
          'Maximum Simultaneous Downloads',
          'Set the maximum number of downloads that can run at the same time',
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: _settings.maxSimultaneousDownloads.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      setState(() {
                        _settings = _settings.copyWith(
                          maxSimultaneousDownloads: parsed,
                        );
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Group by file type
        _buildSettingSection(
          '',
          '',
          CheckboxListTile(
            title: const Text('Group incoming downloads by file type'),
            value: _settings.groupByFileType,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(groupByFileType: value ?? false);
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        if (_settings.groupByFileType) ...[
          const SizedBox(height: 16),
          _buildFileTypeGroupsTable(),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _fileTypeGroups.add({'types': '', 'folder': ''});
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add File Type'),
          ),
        ],

        const SizedBox(height: 32),

        // Download speed limit
        _buildSettingSection(
          '',
          '',
          CheckboxListTile(
            title: const Text('Download speed limit'),
            value: _settings.downloadSpeedLimit,
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(
                  downloadSpeedLimit: value ?? false,
                );
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        if (_settings.downloadSpeedLimit) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _settings.speedLimitValue,
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  onChanged: (value) {
                    setState(() {
                      _settings = _settings.copyWith(speedLimitValue: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _settings.speedLimitValue.toInt().toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed >= 10 && parsed <= 1000) {
                      setState(() {
                        _settings = _settings.copyWith(speedLimitValue: parsed);
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _settings.speedLimitUnit,
                items: ['KB/s', 'MB/s'].map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(speedLimitUnit: value!);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Limit the maximum download speed to prevent affecting other network activities',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ],
    );
  }

  Widget _buildFileTypeGroupsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'File Types',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Sub-folder',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(width: 48),
              ],
            ),
          ),
          // Table rows
          ...List.generate(_fileTypeGroups.length, (index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _fileTypeGroups[index]['types'],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onChanged: (value) {
                        _fileTypeGroups[index]['types'] = value;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: _fileTypeGroups[index]['folder'],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      onChanged: (value) {
                        _fileTypeGroups[index]['folder'] = value;
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fileTypeGroups.removeAt(index);
                      });
                    },
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Other sections remain the same as before...
  Widget _buildGeneralContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingSection(
          'Language',
          'Choose your preferred language',
          DropdownButtonFormField<String>(
            value: _settings.language,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['English', 'Spanish', 'French', 'German'].map((lang) {
              return DropdownMenuItem(value: lang, child: Text(lang));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(language: value!);
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingSection(
          'Theme',
          'Choose your preferred appearance',
          DropdownButtonFormField<String>(
            value: _settings.theme,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['System', 'Light', 'Dark'].map((theme) {
              return DropdownMenuItem(value: theme, child: Text(theme));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _settings = _settings.copyWith(theme: value!);
              });
            },
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          title: const Text('Start with system'),
          subtitle: const Text('Launch download manager when system starts'),
          value: _settings.startWithSystem,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(startWithSystem: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Minimize to system tray'),
          subtitle: const Text(
            'Keep running in background when window is closed',
          ),
          value: _settings.minimizeToTray,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(minimizeToTray: value ?? false);
            });
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text('Clear download history on exit'),
          subtitle: const Text(
            'Remove completed downloads from history when app closes',
          ),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Send anonymous usage statistics'),
          subtitle: const Text(
            'Help improve the app by sharing anonymous usage data',
          ),
          value: true,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Clear All Download History'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reset All Settings'),
        ),
      ],
    );
  }

  Widget _buildAdvancedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingSection(
          'Connection timeout',
          'Timeout for download connections (seconds)',
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: '30',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingSection(
          'Retry attempts',
          'Number of times to retry failed downloads',
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: '3',
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          title: const Text('Enable debug logging'),
          subtitle: const Text('Generate detailed logs for troubleshooting'),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Use system proxy settings'),
          subtitle: const Text(
            'Automatically detect and use system proxy configuration',
          ),
          value: true,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAboutContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.download, size: 48, color: Colors.blue),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open Download Manager',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                Text('Version 1.0.0'),
                Text('Build 2024.08.10'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'A free and open-source download manager for desktop and mobile platforms.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        const Text(
          'Copyright © 2024 Open Download Manager Team',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            TextButton(onPressed: () {}, child: const Text('View License')),
            TextButton(onPressed: () {}, child: const Text('Source Code')),
            TextButton(onPressed: () {}, child: const Text('Report Issue')),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          child: const Text('Check for Updates'),
        ),
      ],
    );
  }

  Widget _buildSettingSection(
    String title,
    String description,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
        ],
        if (description.isNotEmpty) ...[
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
        ],
        content,
      ],
    );
  }
}
