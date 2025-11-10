import 'package:flutter/material.dart';
import 'package:open_download_manager/screens/initialization_screen.dart';
import 'package:open_download_manager/utils/theme.dart';
import 'dart:convert';
import 'package:open_download_manager/windows/add_download_window.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();




  // Check if this is the main window or a secondary window
  if (args.firstOrNull == 'multi_window') {

    // This is a secondary window - get the window configuration
    final windowId = int.parse(args[1]);
    final arguments = args[2];

    // Parse the window arguments to get configuration
    final config = jsonDecode(arguments) as Map<String, dynamic>;

    // Run the secondary window app
    runApp(
      AddDownloadWindowApp(
        windowId: windowId,
        windowName: config['name'] as String,
      ),
    );
  } else {
    // This is the main window
    runApp(const OpenDownloadManagerApp());
  }
}

class OpenDownloadManagerApp extends StatelessWidget {
  const OpenDownloadManagerApp({super.key});

  @override
  Widget build(BuildContext context) {


    return MaterialApp(
      title: 'Open Download Manager',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      // Will be updated after config loads
      home: const InitializationScreen(),
    );
  }
}
