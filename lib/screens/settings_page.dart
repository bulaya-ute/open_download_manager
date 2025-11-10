import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_download_manager/widgets/clickable_container.dart';
import 'package:open_download_manager/widgets/custom_snackbar.dart';
import 'package:open_download_manager/widgets/option_selector.dart';
import 'package:open_download_manager/widgets/padded_column.dart';
import 'package:open_download_manager/widgets/settings_option.dart';
import 'package:open_download_manager/widgets/stacked_container_group.dart';
import '../core/config.dart';
import '../models/app_settings.dart';
import '../utils/theme/colors.dart';
// import '../utils/data_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSection = 'General';
  late AppSettings _settings;
  bool _isLoading = true;

  // File type groupings
  List<Map<String, String>> _fileTypeGroups = [];

  final TextEditingController _searchController = TextEditingController();

  void _changeDownloadDir() {
    CustomSnackBar.showMessage(context, "Implement change download dir");
  }

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
            backgroundColor: successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: errorRed,
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
      body: Row(
        children: [
          // Left sidebar
          SizedBox(
            width: 250,
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

          VerticalDivider(),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Header with search
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(100),
                      ),
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
                                color: Theme.of(context).colorScheme.outline,
                              ),
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
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withAlpha(100),
                      ),
                    ),
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: white,
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
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: sidebarSelectedBg,
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
      case 'General':
        return _buildGeneralContent();
      case 'Downloads':
        return _buildDownloadsContent();
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
    return PaddedColumn(
      paddingLTRB: [0, 0, 0, 0],
      spacing: 24,
      children: [
        StackedContainerGroup(
          title: "Download Behaviour",
          children: [
            // Download folder
            ExtendedSettingsOption(
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    "Download Folder",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      // color: effectiveTitleColor,
                    ),
                  ),

                  SizedBox(height: 2),

                  // Subtitle
                  Text(
                    "All downloads will be saved here",
                    style: TextStyle(
                      fontSize: 13,
                      // color: effectiveSubtitleColor,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 8),

                  ClickableContainer(
                    padding: EdgeInsets.all(8),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceBright,
                    borderRadius: 8,
                    borderColor: Theme.of(context).colorScheme.outline,
                    child: Row(
                      children: [
                        Icon(Icons.folder_open_outlined),
                        SizedBox(width: 8),
                        Expanded(child: Text(Config.downloadDir!)),
                        SizedBox(width: 8),
                        ClickableContainer(
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withAlpha(128),
                          padding: EdgeInsets.all(12),
                          borderRadius: 8,
                          borderColor: Theme.of(context).colorScheme.outline,
                          onTap: _changeDownloadDir,
                          child: Text("Change"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Download grouping
            ExtendedSettingsOption(
              prefix: Checkbox(
                value: true,
                onChanged: (value) => _setDownloadOrganizing(value),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    "Organize downloads in subfolders",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      // color: effectiveTitleColor,
                    ),
                  ),

                  SizedBox(height: 2),

                  // Subtitle
                  Text(
                    "Downloads will be saved in subfolders based on file type",
                    style: TextStyle(
                      fontSize: 13,
                      // color: effectiveSubtitleColor,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 8),

                  _DownloadOrganizationRow(
                    directoryName: "Videos",
                    extensions: {"mp4", "mkv", "webm"},
                  ),

                  _DownloadOrganizationRow(
                    directoryName: "Images",
                    extensions: {"png", "jpg", "jpeg"},
                  ),

                  _DownloadOrganizationRow(
                    directoryName: "Documents",
                    extensions: {"txt", "pdf", "doc", "docx", "xlsx"},
                  ),

                  Container(
                    margin: EdgeInsets.only(top: 16),
                    child: ClickableContainer(
                      padding: EdgeInsets.all(12),
                      borderRadius: 8,
                      onTap: () {
                        CustomSnackBar.showMessage(context, "Add rule");
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Add Rule",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pre-download confirmation option
            SettingsOption(
              title: "Start downloading before confirmation",
              subtitle:
                  "Starts downloading in the background the moment the confirmation dialog appears",
              suffix: Switch(value: true, onChanged: (value) {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFileTypeGroupsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withAlpha(100),
                  ),
                ),
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
        StackedContainerGroup(
          title: "Appearance",
          children: [
            SettingsOption(
              title: "Language",
              prefixIcon: Icons.language_outlined,
              suffix: DropdownButton<String>(
                value: "English",
                items: ["English"].map((lang) {
                  return DropdownMenuItem(value: lang, child: Text(lang));
                }).toList(),
                onChanged: (final val) {},
              ),
            ),
            SettingsOption(
              title: "Theme",
              prefixIcon: Icons.contrast,
              suffix: OptionSelector(
                value: "Light",
                options: ["Light", "Dark", "System"],
                onChanged: (onChanged) {},
              ),
            ),
          ],
        ),

        SizedBox(height: 24),

        StackedContainerGroup(
          title: "Behavior",
          children: [
            SettingsOption(
              title: "Launch on system startup",
              prefixIcon: Icons.rocket_launch,
              suffix: Switch(value: true, onChanged: (value) {}),
            ),
            SettingsOption(
              title: "Check for updates automatically",
              prefixIcon: Icons.update,
              suffix: Switch(value: true, onChanged: (value) {}),
            ),
          ],
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
          style: ElevatedButton.styleFrom(backgroundColor: errorRed),
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
        Row(
          children: [
            Icon(
              Icons.download,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
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
        Text(
          'Copyright © 2024 Open Download Manager Team',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        content,
      ],
    );
  }

  void _setDownloadOrganizing(bool? value) {}
}

class _DownloadOrganizationRow extends StatefulWidget {
  final String directoryName;
  final Set<String> extensions;

  const _DownloadOrganizationRow({
    super.key,
    required this.directoryName,
    required this.extensions,
  });

  @override
  State<_DownloadOrganizationRow> createState() =>
      _DownloadOrganizationRowState();
}

class _DownloadOrganizationRowState extends State<_DownloadOrganizationRow> {
  double leadColWidth = 200;
  double gap = 24;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        // Row(
        //   children: [
        //     SizedBox(
        //       width: leadColWidth,
        //       child: Text(
        //         "Subdirectory Name",
        //         style: TextStyle(fontSize: 13, height: 1.2),
        //       ),
        //     ),
        //     SizedBox(width: gap),
        //
        //     Expanded(
        //       child: Text(
        //         "File Types",
        //         style: TextStyle(fontSize: 13, height: 1.2),
        //       ),
        //     ),
        //   ],
        // ),
        SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: leadColWidth,
              child: ClickableContainer(
                borderColor: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceBright,
                padding: EdgeInsets.all(8),
                child: Text(widget.directoryName),
              ),
            ),

            SizedBox(width: gap),

            Expanded(
              child: ClickableContainer(
                borderColor: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceBright,
                // padding: EdgeInsets.all(5),
                child: Wrap(
                  children:
                      widget.extensions
                          .map(
                            (extension) => Container(
                              margin: EdgeInsets.all(5),
                              child: ClickableContainer(
                                borderColor: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                borderRadius: 8,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.surfaceBright,
                                padding: EdgeInsets.all(5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 0.8,
                                      ),

                                      extension,
                                    ),
                                    SizedBox(width: 4),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        CustomSnackBar.showMessage(
                                          context,
                                          "Remove",
                                        );
                                      },
                                      child: Icon(Icons.close, size: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList() +
                      [
                        Container(
                          margin: EdgeInsets.all(5),
                          child: ClickableContainer(
                            borderColor: Theme.of(context).colorScheme.primary,
                            borderRadius: 8,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surfaceBright,
                            padding: EdgeInsets.all(5),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                CustomSnackBar.showMessage(context, "Add");
                              },
                              child: Icon(
                                Icons.add,
                                color: Theme.of(context).colorScheme.primary,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                ),
              ),
            ),

            TextButton(
              onPressed: () {},
              child: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
