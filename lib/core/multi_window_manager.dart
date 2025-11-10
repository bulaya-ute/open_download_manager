import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

class MultiWindowManager {
  static int? manualAddDownloadWindowId;
  
  static final String _moduleName = "WINDOW MGR";
  static final List<WindowInfo> _windows = [];

  static void sendMessageToMain(String message) async {
    await sendMessageToWindow(0, message);
  }

  static Future<void> sendMessageToWindow(int windowId, String message) async {
    try {
      final response = await DesktopMultiWindow.invokeMethod(
        windowId,
        'message_from_main',
        'Hello from main window!',
      );
    } catch (e) {
      print('Failed to send message: $e');
    }
  }

  static int? get addDownloadWindowId {
    for (final windowDetails in _windows) {
      if (windowDetails.name == "Add Download") return windowDetails.id;
    }
    return null;
  }

  static Future<int?> createWindow(String windowName) async {
    if (addDownloadWindowId != null) {
      focusWindow(addDownloadWindowId!);
      return null;
    }
    
    try {
      
      // Set window details
      // final name = 'Window $_windowCounter';
      final windowConfig = {'name': windowName};

      // Create the new window
      final windowController = await DesktopMultiWindow.createWindow(
        jsonEncode(windowConfig),
      );

      // Configure the window using the controller
      windowController
        ..setFrame(const Offset(100, 100) & const Size(700, 330))
        ..setTitle(windowName)
        ..show();

      // Add to our tracking list
      _windows.add(
        WindowInfo(
          id: windowController.windowId,
          name: windowName,
          controller: windowController,
        ),
      );

      // Return the window id
      return windowController.windowId;
    } catch (e) {
      print('Failed to create window: $e');
      return null;
    }
  }

  static Future<void> closeWindow(int windowId) async {
    try {
      // Find the window controller for this window ID
      final windowInfo = _windows.firstWhere((w) => w.id == windowId);

      // Use the controller's close method
      await windowInfo.controller.close();

      _windows.removeWhere((w) => w.id == windowId);
    } catch (e) {
      print('Failed to close window: $e');
    }
  }

  static Future<void> focusWindow(int windowId) async {
    try {
      // Find the window controller for this window ID
      final windowInfo = _windows.firstWhere((w) => w.id == windowId);

      // Use the controller's close method
      await windowInfo.controller.show();

      _windows.removeWhere((w) => w.id == windowId);
    } catch (e) {
      print('Failed to close window: $e');
    }
  }

  static void print(dynamic message) {
    debugPrint("[$_moduleName] ${message ?? ''}");
  }
}

class WindowInfo {
  final int id;
  final String name;
  final WindowController controller;

  WindowInfo({required this.id, required this.name, required this.controller});
}
