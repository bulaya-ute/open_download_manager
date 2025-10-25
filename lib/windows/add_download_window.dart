import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddDownloadWindowApp extends StatelessWidget {
  final int windowId;
  final String windowName;

  const AddDownloadWindowApp({
    super.key,
    required this.windowId,
    required this.windowName,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: windowName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: AddDownloadWindow(windowId: windowId, windowName: windowName),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AddDownloadWindow extends StatefulWidget {
  final int windowId;
  final String windowName;

  const AddDownloadWindow({
    super.key,
    required this.windowId,
    required this.windowName,
  });

  @override
  State<AddDownloadWindow> createState() => _AddDownloadWindowState();
}

class _AddDownloadWindowState extends State<AddDownloadWindow> {
  @override
  void initState() {
    super.initState();

    // Listen for messages from the main window
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.windowName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: TextButton(
          onPressed: _sendMessageToMain,
          child: const Text('Send a message to the main window'),
        ),
      ),
    );
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int fromWindowId) async {
    if (call.method == 'message_from_main') {
      final message = call.arguments.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return 'Message received by secondary window ${widget.windowId}';
    }
    return null;
  }

  Future<void> _sendMessageToMain() async {
    try {
      if (mounted) {
        await DesktopMultiWindow.invokeMethod(
        0, // Main window always has ID 0
        'message_from_secondary',
        'Hello from ${widget.windowName}!',
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
      }
    }
  }
}
