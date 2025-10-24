import 'package:flutter/material.dart';
import 'package:open_download_manager/screens/downloads_page.dart';
import 'package:open_download_manager/utils/config.dart';
import 'package:open_download_manager/utils/download_engine.dart';
import 'package:open_download_manager/utils/download_service.dart';

/// Initialization screen that loads all required resources before showing the main app
class InitializationScreen extends StatefulWidget {
  const InitializationScreen({super.key});

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  String _statusMessage = 'Initializing...';
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Config
      setState(() {
        _statusMessage = 'Loading configuration...';
      });
      await Config.init();
      await Future.delayed(const Duration(milliseconds: 300)); // Small delay for visual feedback

      // Step 2: Initialize Download Engine
      setState(() {
        _statusMessage = 'Initializing download engine...';
      });
      DownloadEngine.init();
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Load Downloads
      setState(() {
        _statusMessage = 'Loading downloads...';
      });
      await DownloadService.loadDownloads(skipMissingFiles: false);
      await Future.delayed(const Duration(milliseconds: 300));

      // Initialization complete - navigate to main page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const DownloadManagerHomePage(),
          ),
        );
      }
    } catch (e) {
      // Handle initialization errors
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _statusMessage = 'Initialization failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon (optional)
            Icon(
              Icons.download,
              size: 80,
              color: _hasError ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 32),

            // App name
            const Text(
              'Open Download Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator or error icon
            if (!_hasError) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: SelectableText(
                  _errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _errorMessage = null;
                    _statusMessage = 'Initializing...';
                  });
                  _initializeApp();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
