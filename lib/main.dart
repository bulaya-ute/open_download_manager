import 'package:flutter/material.dart';
import 'package:open_download_manager/screens/initialization_screen.dart';
import 'package:open_download_manager/utils/theme/theme_builder.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeBuilder.createCustomThemePair(
      primarySeedColor: Colors.blue,
      secondarySeedColor: Colors.deepPurpleAccent,
      maxPrimaryDarkOffset: 0.00,
      // maxSecondaryLightOffset: 0.05,
    );

    return MaterialApp(
      title: 'Open Download Manager',
      theme: themeData["light"],
      darkTheme: themeData["dark"],
      themeMode: ThemeMode.light, // Will be updated after config loads
      home: const InitializationScreen(),
    );
  }
}

