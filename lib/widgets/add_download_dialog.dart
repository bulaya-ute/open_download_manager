import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum FilenameStatus { loading, success, error, none }

class AddDownloadDialog extends StatefulWidget {
  const AddDownloadDialog({super.key});

  @override
  State<AddDownloadDialog> createState() => _AddDownloadDialogState();
}

class _AddDownloadDialogState extends State<AddDownloadDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _filenameController = TextEditingController();
  FilenameStatus _filenameStatus = FilenameStatus.none;
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onUrlChanged);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _filenameController.dispose();
    super.dispose();
  }

  void _onUrlChanged() {
    final url = _urlController.text.trim();
    final bool isValid = _isValidUrlFormat(url);
    
    setState(() {
      _isValidUrl = isValid;
    });

    if (isValid) {
      _extractOrFetchFilename(url);
    } else {
      setState(() {
        _filenameController.clear();
        _filenameStatus = FilenameStatus.none;
      });
    }
  }

  bool _isValidUrlFormat(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _extractOrFetchFilename(String url) async {
    // First try to extract filename from URL
    String? extractedFilename = _extractFilenameFromUrl(url);
    
    if (extractedFilename != null) {
      setState(() {
        _filenameController.text = extractedFilename;
        _filenameStatus = FilenameStatus.success;
      });
    } else {
      // Set generic filename and start loading
      setState(() {
        _filenameController.text = 'download.bin';
        _filenameStatus = FilenameStatus.loading;
      });
      
      // Try to fetch filename from server
      await _fetchFilenameFromServer(url);
    }
  }

  String? _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      
      if (segments.isNotEmpty) {
        final lastSegment = segments.last;
        if (lastSegment.contains('.') && !lastSegment.endsWith('/')) {
          return lastSegment;
        }
      }
    } catch (e) {
      // If parsing fails, return null
    }
    return null;
  }

  Future<void> _fetchFilenameFromServer(String url) async {
    try {
      // Simulate server request delay
      await Future.delayed(const Duration(seconds: 1));
      
      // This is a simplified simulation. In a real app, you would:
      // 1. Make a HEAD request to the URL
      // 2. Check the Content-Disposition header
      // 3. Extract filename from the header
      
      // For demo purposes, we'll simulate different outcomes
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      String filename;
      if (host.contains('github')) {
        filename = 'repository_archive.zip';
      } else if (host.contains('google')) {
        filename = 'document.pdf';
      } else if (host.contains('youtube') || host.contains('youtu.be')) {
        filename = 'video.mp4';
      } else {
        // Simulate a failed request
        setState(() {
          _filenameStatus = FilenameStatus.error;
        });
        return;
      }
      
      setState(() {
        _filenameController.text = filename;
        _filenameStatus = FilenameStatus.success;
      });
    } catch (e) {
      setState(() {
        _filenameStatus = FilenameStatus.error;
      });
    }
  }

  void _retryFetchFilename() {
    final url = _urlController.text.trim();
    if (_isValidUrlFormat(url)) {
      setState(() {
        _filenameStatus = FilenameStatus.loading;
      });
      _fetchFilenameFromServer(url);
    }
  }

  Widget _buildFilenameStatusIcon() {
    switch (_filenameStatus) {
      case FilenameStatus.loading:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case FilenameStatus.error:
        return Tooltip(
          message: 'Request filename',
          child: InkWell(
            onTap: _retryFetchFilename,
            borderRadius: BorderRadius.circular(4),
            child: const Icon(
              Icons.refresh,
              size: 16,
              color: Colors.orange,
            ),
          ),
        );
      case FilenameStatus.success:
        return const Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green,
        );
      case FilenameStatus.none:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Add New Download',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // URL input field
            const Text(
              'Download URL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/file.zip',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _urlController.clear();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            
            // Filename input field
            const Text(
              'Filename',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _filenameController,
              decoration: InputDecoration(
                hintText: 'Enter filename',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.insert_drive_file),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _buildFilenameStatusIcon(),
                ),
              ),
              onTap: () {
                // Select all text when tapped
                _filenameController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _filenameController.text.length,
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isValidUrl && _filenameController.text.trim().isNotEmpty
                      ? () {
                          Navigator.of(context).pop({
                            'url': _urlController.text.trim(),
                            'filename': _filenameController.text.trim(),
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Add Download'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
