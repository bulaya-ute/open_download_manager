import 'package:flutter/material.dart';

import 'clickable_container.dart';

class SettingsOption extends StatelessWidget {
  final IconData? prefixIcon;
  final String title;
  final String? subtitle;
  final Widget? suffix;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsetsGeometry? padding;
  final bool showChevron;

  const SettingsOption({
    super.key,
    this.prefixIcon,
    required this.title,
    this.subtitle,
    this.suffix,
    this.onTap,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.subtitleStyle,
    this.padding,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default colors
    final effectiveTitleColor = titleColor ?? theme.colorScheme.onSurface;
    final effectiveSubtitleColor =
        subtitleColor ?? theme.colorScheme.onSurface.withAlpha(200);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;

    // Build the suffix widget
    Widget? effectiveSuffix = suffix;
    if (effectiveSuffix == null && showChevron && onTap != null) {
      effectiveSuffix = Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withAlpha(100),
        size: 20,
      );
    }

    return ClickableContainer(
      onTap: onTap,
      backgroundColor: backgroundColor ?? Colors.transparent,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Prefix icon
          if (prefixIcon != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: effectiveIconColor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                prefixIcon,
                color: effectiveIconColor,
                size: iconSize ?? 20,
              ),
            ),
            SizedBox(width: 16),
          ],

          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style:
                      titleStyle ??
                      TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: effectiveTitleColor,
                      ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        subtitleStyle ??
                        TextStyle(
                          fontSize: 13,
                          color: effectiveSubtitleColor,
                          height: 1.2,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Suffix widget
          if (effectiveSuffix != null) ...[
            SizedBox(width: 16),
            effectiveSuffix,
          ],
        ],
      ),
    );
  }
}

class ExtendedSettingsOption extends StatelessWidget {
  final Widget? prefix;
  final Widget body;
  final String? subtitle;
  final Widget? suffix;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? iconColor;
  final double? iconSize;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final EdgeInsetsGeometry? padding;
  final bool showChevron;

  const ExtendedSettingsOption({
    super.key,
    this.prefix,
    required this.body,
    this.subtitle,
    this.suffix,
    this.onTap,
    this.backgroundColor,
    this.titleColor,
    this.subtitleColor,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.subtitleStyle,
    this.padding,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default colors
    final effectiveTitleColor = titleColor ?? theme.colorScheme.onSurface;
    final effectiveSubtitleColor =
        subtitleColor ?? theme.colorScheme.onSurface.withAlpha(200);
    final effectiveIconColor = iconColor ?? theme.colorScheme.onSurface;

    // Build the suffix widget
    Widget? effectiveSuffix = suffix;
    if (effectiveSuffix == null && showChevron && onTap != null) {
      effectiveSuffix = Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withAlpha(100),
        size: 20,
      );
    }

    return ClickableContainer(
      onTap: onTap,
      backgroundColor: backgroundColor ?? Colors.transparent,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Prefix icon
          if (prefix != null) ...[
            // Container(
            //   padding: EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: effectiveIconColor.withAlpha(20),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   child: Icon(
            //     prefixIcon,
            //     color: effectiveIconColor,
            //     size: iconSize ?? 20,
            //   ),
            // ),
            prefix!,
            SizedBox(width: 16),
          ],

          // Title and subtitle
          Expanded(
            child: body,
          ),

          // Suffix widget
          if (effectiveSuffix != null) ...[
            SizedBox(width: 16),
            effectiveSuffix,
          ],
        ],
      ),
    );
  }
}
