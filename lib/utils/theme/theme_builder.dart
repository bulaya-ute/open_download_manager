import 'dart:math' as math;

import 'package:flutter/material.dart';

class ThemeBuilder {
  /// Builds a custom theme with the given colors and brightness
  static ThemeData buildTheme({
    required Color primarySeedColor,
    Color? secondarySeedColor,
    Color? surfaceSeedColor,
    required String brightness, // 'light' or 'dark'
  }) {
    final bool isDark = brightness.toLowerCase() == 'dark';
    final Brightness themeBrightness =
        isDark ? Brightness.dark : Brightness.light;

    // Generate secondary color if not provided
    final Color effectiveSecondary =
        secondarySeedColor ?? _generateSecondaryColor(primarySeedColor);

    // Adjust primary color for better contrast in dark themes
    final Color effectivePrimary =
        isDark
            ? _generateLighterPrimaryForDark(primarySeedColor)
            : primarySeedColor;

    // Generate surface colors based on surfaceSeedColor or primarySeedColor
    final Color effectiveSurfaceSeed = surfaceSeedColor ?? primarySeedColor;

    // Generate base color scheme using original seed color for proper MD3 color harmony
    final ColorScheme baseScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: themeBrightness,
    );

    // Override with our controlled colors and proper contrast calculations
    final ColorScheme colorScheme = baseScheme.copyWith(
      primary: effectivePrimary,
      secondary: effectiveSecondary,
      surface:
          isDark
              ? _generateDarkSurface(effectiveSurfaceSeed)
              : _generateLightSurface(effectiveSurfaceSeed),
      surfaceContainerHighest:
          isDark
              ? _generateDarkSurfaceContainer(effectiveSurfaceSeed)
              : _generateLightSurfaceContainer(effectiveSurfaceSeed),
      onPrimary: _generateOnPrimaryColor(effectivePrimary, isDark),
      onSecondary: _generateOnSecondaryColor(effectiveSecondary, isDark),
    );

    return ThemeData(
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color:
            isDark
                ? _generateDarkCardColor(effectiveSurfaceSeed)
                : _generateLightCardColor(effectiveSurfaceSeed),
        elevation: 4,
        margin: const EdgeInsets.all(0),
        shadowColor: Colors.black.withAlpha(60),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? _generateDarkSurface(effectiveSurfaceSeed) : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
    );
  }

  /// Internal method to build theme without automatic color adjustments
  /// Used by createCustomThemePair to have full control over color modifications
  static ThemeData _buildThemeWithoutAutoAdjustments({
    required Color primarySeedColor,
    Color? secondarySeedColor,
    Color? surfaceSeedColor,
    required String brightness,
  }) {
    final bool isDark = brightness.toLowerCase() == 'dark';
    final Brightness themeBrightness =
        isDark ? Brightness.dark : Brightness.light;

    // Generate secondary color if not provided
    final Color effectiveSecondary =
        secondarySeedColor ?? _generateSecondaryColor(primarySeedColor);

    // Use colors as-is, without automatic adjustments
    final Color effectivePrimary = primarySeedColor;

    // Generate surface colors based on surfaceSeedColor or primarySeedColor
    final Color effectiveSurfaceSeed = surfaceSeedColor ?? primarySeedColor;

    // Generate base color scheme using original seed color for proper MD3 color harmony
    // Note: We need to get the original seed color, but since this method receives
    // already-processed colors from createCustomThemePair, we'll use the primarySeedColor
    // which should be the final color we want to use as primary
    final ColorScheme baseScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: themeBrightness,
    );

    // Override with our controlled colors and proper contrast calculations
    final ColorScheme colorScheme = baseScheme.copyWith(
      primary: effectivePrimary,
      secondary: effectiveSecondary,
      surface:
          isDark
              ? _generateDarkSurface(effectiveSurfaceSeed)
              : _generateLightSurface(effectiveSurfaceSeed),
      surfaceContainerHighest:
          isDark
              ? _generateDarkSurfaceContainer(effectiveSurfaceSeed)
              : _generateLightSurfaceContainer(effectiveSurfaceSeed),
      onPrimary: _generateOnPrimaryColor(effectivePrimary, isDark),
      onSecondary: _generateOnSecondaryColor(effectiveSecondary, isDark),
    );

    return ThemeData(
      colorScheme: colorScheme,
      cardTheme: CardThemeData(
        color:
            isDark
                ? _generateDarkCardColor(effectiveSurfaceSeed)
                : _generateLightCardColor(effectiveSurfaceSeed),
        elevation: 4,
        margin: const EdgeInsets.all(0),
        shadowColor: Colors.black.withAlpha(60),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? _generateDarkSurface(effectiveSurfaceSeed) : Colors.white,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
    );
  }

  /// Generates a complementary secondary color based on the primary color
  static Color _generateSecondaryColor(Color primaryColor) {
    final HSLColor hsl = HSLColor.fromColor(primaryColor);
    // Shift hue by 60 degrees for a complementary color
    final double newHue = (hsl.hue + 60) % 360;
    return hsl
        .withHue(newHue)
        .withSaturation(math.min(1.0, hsl.saturation + 0.1))
        .toColor();
  }

  /// Generates dark surface color by blending primary color with dark base
  static Color _generateDarkSurface(Color primaryColor) {
    const Color darkBase = Color(0xff191e2c);
    return Color.alphaBlend(primaryColor.withAlpha(15), darkBase);
  }

  /// Generates dark surface container color
  static Color _generateDarkSurfaceContainer(Color primaryColor) {
    const Color darkContainerBase = Color(0xff242b3d);
    return Color.alphaBlend(primaryColor.withAlpha(20), darkContainerBase);
  }

  /// Generates dark card color by blending primary with dark base
  static Color _generateDarkCardColor(Color primaryColor) {
    const Color darkCardBase = Color(0xff1f2d44);
    return Color.alphaBlend(primaryColor.withAlpha(25), darkCardBase);
  }

  /// Generates light card color by blending primary with white
  static Color _generateLightCardColor(Color primaryColor) {
    return Color.alphaBlend(primaryColor.withAlpha(20), Colors.white);
  }

  /// Generates light surface color - white with a subtle hint of the surface seed color
  static Color _generateLightSurface(Color surfaceSeedColor) {
    // For light theme, use mostly white with a very subtle hint of the surface seed color
    return Color.alphaBlend(surfaceSeedColor.withAlpha(8), Colors.white);
  }

  /// Generates light surface container color
  static Color _generateLightSurfaceContainer(Color surfaceSeedColor) {
    // Slightly more tinted than the base surface for containers
    return Color.alphaBlend(surfaceSeedColor.withAlpha(15), Colors.white);
  }

  /// Generates a lighter version of the primary color for dark themes
  /// to ensure better contrast with dark surfaces
  static Color _generateLighterPrimaryForDark(Color primaryColor) {
    final HSLColor hsl = HSLColor.fromColor(primaryColor);

    // Increase lightness by 20-30% for better visibility on dark backgrounds
    // Ensure we don't exceed maximum lightness
    double newLightness = math.min(1.0, hsl.lightness + 0.25);

    // If the color is already very light, slightly reduce saturation instead
    // to prevent it from becoming too washed out
    double newSaturation = hsl.saturation;
    if (hsl.lightness > 0.7) {
      newLightness = math.min(1.0, hsl.lightness + 0.15);
      newSaturation = math.max(0.3, hsl.saturation - 0.1);
    }

    return hsl
        .withLightness(newLightness)
        .withSaturation(newSaturation)
        .toColor();
  }

  /// Generates optimal foreground color based on background color and candidate colors
  /// This method selects the best contrasting color from a list of candidates
  /// based on WCAG contrast ratio standards
  static Color _generateOptimalForegroundColor(
    Color backgroundColor,
    List<Color> candidateColors, {
    double minContrastRatio = 3.0,
  }) {
    final double backgroundLuminance = backgroundColor.computeLuminance();

    // // Debug output for teal colors
    // if (backgroundColor.value == Colors.teal.value ||
    //     backgroundColor.value == 0xFF009688) {
    //   print('DEBUG: _generateOptimalForegroundColor for teal');
    //   print(
    //     '  Background color: ${backgroundColor.toString()} (0x${backgroundColor.value.toRadixString(16).padLeft(8, '0')})',
    //   );
    //   print('  Background luminance: $backgroundLuminance');
    //   print('  Min contrast ratio: $minContrastRatio');
    //   print('  Candidates: ${candidateColors.length}');
    // }

    Color? bestCandidate;
    // double bestContrastRatio = 0.0;

    // Test each candidate color for contrast ratio
    for (int i = 0; i < candidateColors.length; i++) {
      final Color candidate = candidateColors[i];
      final double candidateLuminance = candidate.computeLuminance();
      final double contrastRatio = _calculateContrastRatio(
        backgroundLuminance,
        candidateLuminance,
      );

      // // Debug output for teal colors
      // if (backgroundColor.value == Colors.teal.value ||
      //     backgroundColor.value == 0xFF009688) {
      //   String candidateName =
      //       candidate == Colors.white
      //           ? 'WHITE'
      //           : candidate == Colors.black
      //           ? 'BLACK'
      //           : 'SURFACE (0x${candidate.value.toRadixString(16).padLeft(8, '0')})';
      //   print('  Candidate $i: $candidateName');
      //   print('    Luminance: $candidateLuminance');
      //   print('    Contrast ratio: $contrastRatio');
      //   print(
      //     '    Meets minimum ($minContrastRatio): ${contrastRatio >= minContrastRatio}',
      //   );
      // }

      // If this candidate meets minimum requirements, use it (first wins)
      if (contrastRatio >= minContrastRatio) {
        bestCandidate = candidate;
        // bestContrastRatio = contrastRatio;

        // Debug output for teal colors
        // if (backgroundColor.value == Colors.teal.value ||
        //     backgroundColor.value == 0xFF009688) {
        //   String candidateName =
        //       candidate == Colors.white
        //           ? 'WHITE'
        //           : candidate == Colors.black
        //           ? 'BLACK'
        //           : 'SURFACE';
        //   print(
        //     '    *** SELECTED FIRST SUFFICIENT CANDIDATE: $candidateName with ratio $contrastRatio ***',
        //   );
        // }

        // Stop at first sufficient candidate (priority order)
        break;
      }
    }

    // // Debug final result for teal colors
    // if (backgroundColor.value == Colors.teal.value ||
    //     backgroundColor.value == 0xFF009688) {
    //   String finalName =
    //       bestCandidate == Colors.white
    //           ? 'WHITE'
    //           : bestCandidate == Colors.black
    //           ? 'BLACK'
    //           : bestCandidate == null
    //           ? 'NULL (will generate custom)'
    //           : 'SURFACE';
    //   print('  FINAL RESULT: $finalName with ratio $bestContrastRatio');
    //   print('');
    // }

    // If we found a suitable candidate, return it
    if (bestCandidate != null) {
      return bestCandidate;
    }

    // If no candidates meet requirements, generate a high-contrast color
    return _generateHighContrastColor(backgroundColor);
  }

  /// Generates a high-contrast color for the given background when no candidates suffice
  static Color _generateHighContrastColor(Color backgroundColor) {
    final double backgroundLuminance = backgroundColor.computeLuminance();

    // Calculate contrast ratios with white and black
    final double contrastWithWhite = _calculateContrastRatio(
      backgroundLuminance,
      1.0,
    );
    final double contrastWithBlack = _calculateContrastRatio(
      backgroundLuminance,
      0.0,
    );

    // If neither white nor black provide sufficient contrast, generate a custom color
    if (contrastWithWhite < 4.5 && contrastWithBlack < 4.5) {
      // For very problematic backgrounds, create a color with maximum contrast
      final HSLColor backgroundHsl = HSLColor.fromColor(backgroundColor);

      // Create a color with opposite lightness and high saturation for maximum contrast
      final double targetLightness = backgroundHsl.lightness > 0.5 ? 0.1 : 0.9;
      final double targetSaturation = math.min(
        1.0,
        backgroundHsl.saturation + 0.3,
      );

      return backgroundHsl
          .withLightness(targetLightness)
          .withSaturation(targetSaturation)
          .toColor();
    }

    // Return the better option between white and black
    return contrastWithWhite > contrastWithBlack ? Colors.white : Colors.black;
  }

  /// Generates appropriate onPrimary color based on primary color contrast
  static Color _generateOnPrimaryColor(Color primaryColor, bool isDark) {
    final Color surfaceColor =
        isDark ? _generateDarkSurface(primaryColor) : Colors.white;

    // // Debug output for teal colors
    // if (primaryColor.value == Colors.teal.value ||
    //     primaryColor.value == 0xFF009688) {
    //   print('DEBUG: _generateOnPrimaryColor called');
    //   print(
    //     '  Primary color: ${primaryColor.toString()} (0x${primaryColor.value.toRadixString(16).padLeft(8, '0')})',
    //   );
    //   print('  Is dark theme: $isDark');
    //   print(
    //     '  Surface color: ${surfaceColor.toString()} (0x${surfaceColor.value.toRadixString(16).padLeft(8, '0')})',
    //   );
    // }

    return _generateOptimalForegroundColor(primaryColor, [
      Colors.white,
      Colors.black,
      surfaceColor,
    ]);
  }

  /// Generates appropriate onSecondary color based on secondary color contrast
  static Color _generateOnSecondaryColor(Color secondaryColor, bool isDark) {
    final Color surfaceColor =
        isDark ? _generateDarkSurface(secondaryColor) : Colors.white;

    return _generateOptimalForegroundColor(secondaryColor, [
      Colors.white,
      Colors.black,
      surfaceColor,
    ]);
  }

  /// Applies calculated color offset based on theme brightness and maximum offset
  /// Only adjusts colors when they fall outside the optimal range for their theme
  /// For light themes: darkens colors that are too light
  /// For dark themes: lightens colors that are too dark
  static Color _applyColorOffset(
    Color originalColor,
    double maxOffset, {
    required bool isDark,
  }) {
    if (maxOffset == 0.0) {
      return originalColor;
    }

    final HSLColor hsl = HSLColor.fromColor(originalColor);

    // Define optimal lightness ranges for each theme
    const double lightThemeOptimalMax =
        0.7; // Colors shouldn't be lighter than this in light theme
    const double darkThemeOptimalMin =
        0.4; // Colors should be at least this light in dark theme

    double neededOffset = 0.0;

    if (isDark) {
      // For dark themes: ensure color is light enough to be visible
      if (hsl.lightness < darkThemeOptimalMin) {
        // Color is too dark, needs lightening
        neededOffset = darkThemeOptimalMin - hsl.lightness;
      }
      // If color is already in optimal range, no offset needed
    } else {
      // For light themes: ensure color isn't too light (washed out)
      if (hsl.lightness > lightThemeOptimalMax) {
        // Color is too light, needs darkening
        neededOffset = hsl.lightness - lightThemeOptimalMax;
      }
      // If color is already in optimal range, no offset needed
    }

    // Clamp the needed offset to the maximum allowed
    double actualOffset = math.min(neededOffset, maxOffset);

    // If no offset is needed, return original color
    if (actualOffset == 0.0) {
      return originalColor;
    }

    // Apply the calculated offset
    if (isDark) {
      double newLightness = math.min(1.0, hsl.lightness + actualOffset);

      // Adjust saturation for very light colors to prevent washout
      double newSaturation = hsl.saturation;
      if (newLightness > 0.8) {
        newSaturation = math.max(0.3, hsl.saturation - (actualOffset * 0.5));
      }

      return hsl
          .withLightness(newLightness)
          .withSaturation(newSaturation)
          .toColor();
    } else {
      double newLightness = math.max(0.0, hsl.lightness - actualOffset);

      // Slightly increase saturation when darkening to maintain vibrancy
      double newSaturation = math.min(
        1.0,
        hsl.saturation + (actualOffset * 0.2),
      );

      return hsl
          .withLightness(newLightness)
          .withSaturation(newSaturation)
          .toColor();
    }
  }

  /// Calculates contrast ratio between two luminance values
  static double _calculateContrastRatio(double luminance1, double luminance2) {
    final double lighter = math.max(luminance1, luminance2);
    final double darker = math.min(luminance1, luminance2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Predefined theme configurations
  static const Map<String, Map<String, dynamic>> _themeConfigs = {
    'teal': {
      'name': 'Ocean Teal',
      'primary': Colors.teal,
      'secondary': Colors.amber,
      'surface': Colors.black, // Natural blue color
    },
    'charity': {
      'name': 'Charity Blue',
      'primary': Color(0xFF007AFF), // charityBlue
      'secondary': Colors.deepPurpleAccent,
      'surface': Colors.cyan, // Natural cyan color
    },
    'purple': {
      'name': 'Royal Purple',
      'primary': Colors.deepPurple,
      'secondary': Colors.amber,
      'surface': Colors.purple, // Natural purple color
    },
    'green': {
      'name': 'Nature Green',
      'primary': Colors.green,
      'secondary': Colors.orange,
      'surface': Colors.lightGreen, // Natural light green color
    },
    'red': {
      'name': 'Vibrant Red',
      'primary': Colors.red,
      'secondary': Colors.teal,
      'surface': Colors.pink, // Natural pink color
    },
    'orange': {
      'name': 'Sunset Orange',
      'primary': Colors.deepOrange,
      'secondary': Colors.blue,
      'surface': Colors.orange, // Natural orange color
    },
    'pink': {
      'name': 'Cherry Pink',
      'primary': Colors.pink,
      'secondary': Colors.green,
      'surface': Colors.pinkAccent, // Natural pink accent color
    },
    'indigo': {
      'name': 'Deep Indigo',
      'primary': Colors.indigo,
      'secondary': Colors.orange,
      'surface': Colors.indigo, // Natural indigo color
    },
  };

  /// Gets all available theme configurations
  static Map<String, Map<String, dynamic>> get availableThemes => _themeConfigs;

  /// Gets theme data for a specific theme key and brightness
  static ThemeData getTheme(String themeKey, String brightness) {
    final config = _themeConfigs[themeKey];
    if (config == null) {
      throw ArgumentError('Theme key "$themeKey" not found');
    }

    return buildTheme(
      primarySeedColor: config['primary'] as Color,
      secondarySeedColor: config['secondary'] as Color?,
      surfaceSeedColor: config['surface'] as Color?,
      brightness: brightness,
    );
  }

  /// Gets both light and dark themes for a specific theme key
  static Map<String, ThemeData> getThemePair(String themeKey) {
    return {
      'light': getTheme(themeKey, 'light'),
      'dark': getTheme(themeKey, 'dark'),
    };
  }

  /// Gets all themes (light and dark) for all available theme keys
  static Map<String, Map<String, ThemeData>> getAllThemes() {
    final Map<String, Map<String, ThemeData>> allThemes = {};

    for (final themeKey in _themeConfigs.keys) {
      allThemes[themeKey] = getThemePair(themeKey);
    }

    return allThemes;
  }

  /// Gets theme name for display purposes
  static String getThemeName(String themeKey) {
    final config = _themeConfigs[themeKey];
    return config?['name'] as String? ?? themeKey;
  }

  /// Gets all theme keys
  static List<String> get themeKeys => _themeConfigs.keys.toList();

  /// Gets theme keys with their display names
  static Map<String, String> get themeKeysWithNames {
    final Map<String, String> result = {};
    for (final entry in _themeConfigs.entries) {
      result[entry.key] = entry.value['name'] as String;
    }
    return result;
  }

  /// Helper method to create a custom theme that's not in the predefined list
  static Map<String, ThemeData> createCustomThemePair({
    required Color primarySeedColor,
    Color? secondarySeedColor,
    Color? surfaceSeedColor,
    double maxPrimaryLightOffset = 0.0,
    double maxPrimaryDarkOffset = 0.15,
    double maxSecondaryLightOffset = 0.15,
    double maxSecondaryDarkOffset = 0.15,
  }) {
    return {
      'light': _buildThemeWithoutAutoAdjustments(
        primarySeedColor: _applyColorOffset(
          primarySeedColor,
          maxPrimaryLightOffset,
          isDark: false,
        ),
        secondarySeedColor:
            secondarySeedColor != null
                ? _applyColorOffset(
                  secondarySeedColor,
                  maxSecondaryLightOffset,
                  isDark: false,
                )
                : null,
        surfaceSeedColor: surfaceSeedColor,
        brightness: 'light',
      ),
      'dark': _buildThemeWithoutAutoAdjustments(
        primarySeedColor: _applyColorOffset(
          primarySeedColor,
          maxPrimaryDarkOffset,
          isDark: true,
        ),
        secondarySeedColor:
            secondarySeedColor != null
                ? _applyColorOffset(
                  secondarySeedColor,
                  maxSecondaryDarkOffset,
                  isDark: true,
                )
                : null,
        surfaceSeedColor: surfaceSeedColor,
        brightness: 'dark',
      ),
    };
  }

  /// Validates if a brightness string is valid
  static bool isValidBrightness(String brightness) {
    return brightness.toLowerCase() == 'light' ||
        brightness.toLowerCase() == 'dark';
  }

  /// Gets the current default theme (teal)
  static Map<String, ThemeData> get defaultTheme => getThemePair('teal');
}
