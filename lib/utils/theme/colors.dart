import 'package:flutter/material.dart';

// --- Primary Blues ---

/// A classic, trustworthy mid-tone blue, often used for branding or primary actions.
const Color charityBlue = Color(0xFF007AFF);

/// A lighter, softer blue, good for backgrounds or secondary elements.
const Color lightSkyBlue = Color(0xFF87CEEB);

/// A deeper, more vibrant blue, suitable for important elements or accents.
const Color royalBlue = Color(0xFF4169E1);

/// A very dark blue, excellent for text on light backgrounds or dark mode themes.
const Color midnightBlue = Color(0xFF191970);

/// A subtle, pale blue, can be used for disabled states or very light backgrounds.
const Color powderBlue = Color(0xFFB0E0E6);

// --- Neutral Grays ---

/// A very light gray, often used for backgrounds or dividers.
const Color lightGray = Color(0xFFF5F5F5);

/// A standard medium gray, useful for secondary text or icons.
const Color mediumGray = Color(0xFF8E8E93); // iOS-like gray

/// A darker gray, good for primary text or stronger dividers.
const Color darkGray = Color(0xFF333333);

/// Almost black, for strong emphasis or main text.
const Color nearlyBlack = Color(0xFF1C1C1E); // iOS-like almost black

// --- Semantic Colors ---

/// For success messages, confirmations, or positive actions.
const Color successGreen = Color(0xFF34C759); // iOS-like green

/// For error messages, warnings, or destructive actions.
const Color errorRed = Color(0xFFFF3B30); // iOS-like red

/// For warning messages or highlighting potentially important information.
const Color warningYellow = Color(0xFFFFCC00); // iOS-like yellow

// --- Download Status Colors (Dark Theme) ---

/// Blue for active/downloading state - matches the progress bar in the dark theme
const Color downloadingBlue = Colors.blue;

/// Green for completed downloads - matches the completed state
const Color completedGreen = Colors.green;

/// Amber/Yellow for paused downloads
const Color pausedAmber = Colors.amber;

/// Red for failed/error downloads
const Color downloadErrorRed = Color(0xFFF87171);

/// Gray for progress bar track/background
const Color progressTrackGray = Color(0xFF2F3544);

// --- Download Status Colors (Light Theme Equivalents) ---

/// Blue for active/downloading state - light theme version
const Color downloadingBlueLite = Colors.blue;

/// Green for completed downloads - light theme version
const Color completedGreenLight = Colors.green;

/// Amber for paused downloads - light theme version
const Color pausedAmberLight = Colors.amber;

/// Red for failed/error downloads - light theme version
const Color downloadErrorRedLight = Color(0xFFEF4444);

/// Gray for progress bar track/background - light theme version
const Color progressTrackGrayLight = Color(0xFFE5E7EB);

// --- Settings/Sidebar Colors (from second screenshot) ---

/// Selected sidebar item background (blue tint)
const Color sidebarSelectedBg = Color(0xFF2C4F6F);

/// Sidebar item hover background
const Color sidebarHoverBg = Color(0xFF252D3F);

/// Settings card/container background
const Color settingsCardBg = Color(0xFF1F2733);

/// Settings input field background
const Color settingsInputBg = Color(0xFF252D3F);

// --- Accent Colors (Examples - choose ones that fit your brand) ---
// It's good to have a few accent colors that complement your primary blue.

/// A warm accent color.
const Color accentOrange = Color(0xFFFF9500); // iOS-like orange

/// A cool accent color.
const Color accentTeal = Color(0xFF5AC8FA); // iOS-like teal

// --- Standard Material Colors (for quick access if needed) ---
// You can directly use Colors.white, Colors.black, Colors.transparent

/// Standard white color.
const Color white = Colors.white;

/// Standard black color.
const Color black = Colors.black;

/// Standard transparent color.
const Color transparent = Colors.transparent;

// --- Cached Theme Colors with Memoization ---

class ThemeColors {
  // Cache structure for storing calculated colors
  static final Map<String, dynamic> _colorCache = {};

  // Cache keys for different color types
  static const String _elevatedBackgroundKey = 'elevated_background';
  static const String _elevatedBorderKey = 'elevated_border';
  static const String _elevatedShadowKey = 'elevated_shadow';
  static const String _primaryThemeKey = 'primary_theme';
  static const String _surfaceThemeKey = 'surface_theme';
  static const String _brightnessKey = 'brightness';

  /// Clears the color cache (useful for theme changes)
  static void clearCache() {
    _colorCache.clear();
  }

  /// Check if theme has changed and clear cache if necessary
  static void _validateThemeCache(BuildContext context) {
    final currentPrimary = Theme.of(context).colorScheme.primary;
    final currentSurface = Theme.of(context).colorScheme.surface;
    final currentBrightness = Theme.of(context).brightness;

    final cachedPrimary = _colorCache[_primaryThemeKey];
    final cachedSurface = _colorCache[_surfaceThemeKey];
    final cachedBrightness = _colorCache[_brightnessKey];

    if (cachedPrimary != currentPrimary ||
        cachedSurface != currentSurface ||
        cachedBrightness != currentBrightness) {
      clearCache();
      _colorCache[_primaryThemeKey] = currentPrimary;
      _colorCache[_surfaceThemeKey] = currentSurface;
      _colorCache[_brightnessKey] = currentBrightness;
    }
  }

  /// Gets the standard elevated background color used throughout the app
  static Color getElevatedBackgroundColor(BuildContext context) {
    _validateThemeCache(context);

    if (_colorCache.containsKey(_elevatedBackgroundKey)) {
      return _colorCache[_elevatedBackgroundKey] as Color;
    }

    final themeColor = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    final backgroundColor = Theme.of(context).cardTheme.color!;

    _colorCache[_elevatedBackgroundKey] = backgroundColor;
    return backgroundColor;
  }

  /// Gets the standard elevated border color used throughout the app
  static Color getElevatedBorderColor(BuildContext context) {
    _validateThemeCache(context);

    if (_colorCache.containsKey(_elevatedBorderKey)) {
      return _colorCache[_elevatedBorderKey] as Color;
    }

    final themeColor = Theme.of(context).colorScheme.primary;
    final surface = Theme.of(context).colorScheme.surface;

    final borderColor = Color.alphaBlend(themeColor.withAlpha(40), surface);

    _colorCache[_elevatedBorderKey] = borderColor;
    return borderColor;
  }

  /// Gets the standard elevated shadow color used throughout the app
  static Color getElevatedShadowColor(BuildContext context) {
    _validateThemeCache(context);

    if (_colorCache.containsKey(_elevatedShadowKey)) {
      return _colorCache[_elevatedShadowKey] as Color;
    }

    final shadowColor = Colors.black.withAlpha(64);
    _colorCache[_elevatedShadowKey] = shadowColor;
    return shadowColor;
  }

  /// Gets all elevated colors in one call for efficiency
  static ElevatedColorScheme getElevatedColors(BuildContext context) {
    return ElevatedColorScheme(
      background: getElevatedBackgroundColor(context),
      border: getElevatedBorderColor(context),
      shadow: getElevatedShadowColor(context),
    );
  }

  /// Gets primary color with different alpha levels (cached)
  static Color getPrimaryWithAlpha(BuildContext context, int alpha) {
    _validateThemeCache(context);

    final key = 'primary_alpha_$alpha';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Theme.of(context).colorScheme.primary.withAlpha(alpha);
    _colorCache[key] = color;
    return color;
  }

  /// Gets secondary color with different alpha levels (cached)
  static Color getSecondaryWithAlpha(BuildContext context, int alpha) {
    _validateThemeCache(context);

    final key = 'secondary_alpha_$alpha';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Theme.of(context).colorScheme.secondary.withAlpha(alpha);
    _colorCache[key] = color;
    return color;
  }

  /// Gets surface color with different alpha levels (cached)
  static Color getSurfaceWithAlpha(BuildContext context, int alpha) {
    _validateThemeCache(context);

    final key = 'surface_alpha_$alpha';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Theme.of(context).colorScheme.surface.withAlpha(alpha);
    _colorCache[key] = color;
    return color;
  }

  /// Gets focused border color for interactive elements
  static Color getFocusedBorderColor(BuildContext context) {
    _validateThemeCache(context);

    const key = 'focused_border';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Theme.of(context).colorScheme.primary;
    _colorCache[key] = color;
    return color;
  }

  /// Gets hint text color
  static Color getHintTextColor(BuildContext context) {
    _validateThemeCache(context);

    const key = 'hint_text';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Theme.of(context).colorScheme.onSurface.withAlpha(200);
    _colorCache[key] = color;
    return color;
  }

  /// Gets disabled color for buttons and inactive elements
  static Color getDisabledColor(BuildContext context) {
    _validateThemeCache(context);

    const key = 'disabled_color';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Colors.grey[400]!;
    _colorCache[key] = color;
    return color;
  }

  /// Gets selected tab color
  static Color getSelectedTabColor(BuildContext context) {
    _validateThemeCache(context);

    const key = 'selected_tab';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Color.alphaBlend(
      Theme.of(context).colorScheme.primary.withAlpha(200),
      Theme.of(context).textTheme.bodyMedium!.color!,
    );
    _colorCache[key] = color;
    return color;
  }

  /// Gets unselected tab color
  static Color getUnselectedTabColor(BuildContext context) {
    _validateThemeCache(context);

    const key = 'unselected_tab';
    if (_colorCache.containsKey(key)) {
      return _colorCache[key] as Color;
    }

    final color = Color.alphaBlend(
      Theme.of(context).textTheme.bodyMedium!.color!.withAlpha(160),
      Theme.of(context).colorScheme.surface,
    );
    _colorCache[key] = color;
    return color;
  }

  /// Debug method to check cache size
  static int getCacheSize() {
    return _colorCache.length;
  }

  /// Debug method to get cache keys
  static List<String> getCacheKeys() {
    return _colorCache.keys.cast<String>().toList();
  }
}

/// A convenient class to hold all elevated color values
class ElevatedColorScheme {
  final Color background;
  final Color border;
  final Color shadow;

  const ElevatedColorScheme({
    required this.background,
    required this.border,
    required this.shadow,
  });

  /// Creates a BoxDecoration with the elevated colors
  BoxDecoration createBoxDecoration({
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? customShadows,
  }) {
    return BoxDecoration(
      color: background,
      border: border ?? Border.all(color: this.border),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      boxShadow:
          customShadows ??
          [BoxShadow(color: shadow, blurRadius: 4, offset: Offset(0, 4))],
    );
  }

  /// Creates a circular BoxDecoration for buttons
  BoxDecoration createCircularDecoration({List<BoxShadow>? customShadows}) {
    return BoxDecoration(
      color: background,
      border: Border.all(color: border),
      shape: BoxShape.circle,
      boxShadow:
          customShadows ??
          [BoxShadow(color: shadow, blurRadius: 4, offset: Offset(0, 2))],
    );
  }

  /// Creates a pill-shaped BoxDecoration
  BoxDecoration createPillDecoration({List<BoxShadow>? customShadows}) {
    return BoxDecoration(
      color: background,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(30),
      boxShadow:
          customShadows ??
          [BoxShadow(color: shadow, blurRadius: 4, offset: Offset(0, 4))],
    );
  }
}
