import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedSection = 'Downloads';

  // Settings values
  String _defaultDownloadLocation = 'Downloads';
  int _maxSimultaneousDownloads = 4;
  bool _groupByFileType = false;
  bool _downloadSpeedLimit = false;
  double _speedLimitValue = 50;
  String _speedLimitUnit = 'KB/s';
  String _selectedTheme = 'System'; // Added theme selection

  // File type groupings
  final List<Map<String, String>> _fileTypeGroups = [
    {'types': 'png, jpeg, jpg', 'folder': 'Images'},
    {'types': 'mp4, webm,', 'folder': 'Videos'},
    {'types': 'Documents', 'folder': 'Documents'},
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 900,
        height: 700,
        child: Row(
          children: [
            // Left sidebar
            Container(
              width: 250,
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings title
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Settings sections
                  Expanded(
                    child: ListView(
                      children: [
                        _buildSidebarItem(Icons.settings, 'General'),
                        _buildSidebarItem(Icons.download, 'Downloads'),
                        _buildSidebarItem(Icons.palette, 'Appearance'),
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
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
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
                          onPressed: () {
                            // Save settings
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Settings saved successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
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
      case 'Appearance':
        return _buildAppearanceContent();
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
              Text(_defaultDownloadLocation),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Open folder picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Folder picker coming soon')),
                  );
                },
                child: const Text('Browse'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _defaultDownloadLocation = 'Downloads';
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
                  initialValue: _maxSimultaneousDownloads.toString(),
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
                        _maxSimultaneousDownloads = parsed;
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
            value: _groupByFileType,
            onChanged: (value) {
              setState(() {
                _groupByFileType = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        // if (_groupByFileType) ...[
        Row(
          children: [
            SizedBox(width: 16),
            Column(
              children: [
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
            ),
          ],
        ),

        // ],
        const SizedBox(height: 32),

        // Download speed limit
        _buildSettingSection(
          '',
          '',
          CheckboxListTile(
            title: const Text('Download speed limit'),
            value: _downloadSpeedLimit,
            onChanged: (value) {
              setState(() {
                _downloadSpeedLimit = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),

        if (_downloadSpeedLimit) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _speedLimitValue,
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  onChanged: (value) {
                    setState(() {
                      _speedLimitValue = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: _speedLimitValue.toInt().toString(),
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
                        _speedLimitValue = parsed;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _speedLimitUnit,
                items: ['KB/s', 'MB/s'].map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _speedLimitUnit = value!;
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
                    child: Text(_fileTypeGroups[index]['types']!),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(_fileTypeGroups[index]['folder']!),
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

  Widget _buildGeneralContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingSection(
          'Language',
          'Choose your preferred language',
          DropdownButtonFormField<String>(
            value: 'English',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['English', 'Spanish', 'French', 'German'].map((lang) {
              return DropdownMenuItem(value: lang, child: Text(lang));
            }).toList(),
            onChanged: (value) {},
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingSection(
          'Theme',
          'Choose your preferred appearance',
          DropdownButtonFormField<String>(
            value: 'System',
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: ['System', 'Light', 'Dark'].map((theme) {
              return DropdownMenuItem(value: theme, child: Text(theme));
            }).toList(),
            onChanged: (value) {},
          ),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          title: const Text('Start with system'),
          subtitle: const Text('Launch download manager when system starts'),
          value: true,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
        CheckboxListTile(
          title: const Text('Minimize to system tray'),
          subtitle: const Text(
            'Keep running in background when window is closed',
          ),
          value: false,
          onChanged: (value) {},
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAppearanceContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingSection(
          'Theme',
          'Choose your preferred appearance theme',
          Column(
            children: [
              RadioListTile<String>(
                title: const Text('System'),
                subtitle: const Text('Follow system theme settings'),
                value: 'System',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Light'),
                subtitle: const Text('Use light theme'),
                value: 'Light',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: const Text('Dark'),
                subtitle: const Text('Use dark theme'),
                value: 'Dark',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Theme changes will be applied after restarting the application.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
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
                Text('Build 2025.08.10'),
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
          'Copyright © 2025 Open Download Manager Team',
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
