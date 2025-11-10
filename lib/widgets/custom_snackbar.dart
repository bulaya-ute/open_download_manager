import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomSnackBar {
  static void showMessage(
    BuildContext context,
    String message, {
    int durationSeconds = 0,
    bool isError = false,
  }) {
    // Calculate duration based on message length
    if (durationSeconds == 0) {
      durationSeconds = (message.length * 0.7) ~/ 10 + 1;
    }

    final Duration duration = Duration(seconds: durationSeconds);

    // Use SnackBar for desktop platforms
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(

        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
        duration: duration,
        backgroundColor: isError ? Colors.red : Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
