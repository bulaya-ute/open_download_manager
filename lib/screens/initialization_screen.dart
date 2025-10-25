import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_download_manager/screens/downloads_page.dart';
import 'package:open_download_manager/core/download_engine.dart';
import 'package:open_download_manager/utils/download_service.dart';
import 'package:open_download_manager/utils/theme/colors.dart';

import '../core/config.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon (optional)
            Icon(
              Icons.download,
              size: 80,
              color: _hasError ? errorRed : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // App name
            Text(
              'Open Download Manager',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 48),

            // Loading indicator or error icon
            if (!_hasError) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Icon(
                Icons.error_outline,
                size: 64,
                color: errorRed,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: errorRed,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorRed.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: errorRed.withAlpha(100)),
                ),
                child: SelectableText(
                  _errorMessage ?? 'Unknown error',
                  style: TextStyle(
                    fontSize: 14,
                    color: errorRed,
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
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: white,
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
