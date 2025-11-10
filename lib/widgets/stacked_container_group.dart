import 'package:flutter/material.dart';
import 'package:open_download_manager/widgets/section_title.dart';

class StackedContainerGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final double borderRadius;
  final Color? dividerColor;
  final Color? borderColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? margin;
  final List<BoxShadow>? boxShadow;

  const StackedContainerGroup({
    super.key,
    required this.children,
    this.title,
    this.borderRadius = 16,
    this.dividerColor,
    this.borderColor,
    this.backgroundColor,
    this.margin,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Default colors based on theme
    final effectiveDividerColor = theme.colorScheme.onSurface.withAlpha(50);
    final effectiveBorderColor =
        borderColor ?? theme.colorScheme.outline.withAlpha(30);
    final effectiveBackgroundColor = backgroundColor ?? theme.cardTheme.color;

    final List<Widget> stackedChildren = [];

    for (int i = 0; i < children.length; i++) {
      final isFirst = i == 0;
      final isLast = i == children.length - 1;

      final radius = BorderRadius.only(
        topLeft: Radius.circular(isFirst ? borderRadius : 0),
        topRight: Radius.circular(isFirst ? borderRadius : 0),
        bottomLeft: Radius.circular(isLast ? borderRadius : 0),
        bottomRight: Radius.circular(isLast ? borderRadius : 0),
      );

      final child = Container(
        decoration: BoxDecoration(
          color: effectiveBackgroundColor,
          borderRadius: radius,
        ),
        child: ClipRRect(borderRadius: radius, child: children[i]),
      );

      stackedChildren.add(child);

      // Add divider between items (but not after the last item)
      if (!isLast) {
        stackedChildren.add(
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: 16),
            color: effectiveDividerColor,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          SectionTitle(text: title!),
          SizedBox(height: 12,)
        ],

        Container(
          margin: margin,
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorderColor),
            boxShadow:
                boxShadow ??
                [
                  BoxShadow(
                    color: theme.cardTheme.shadowColor ?? Colors.black,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: stackedChildren,
            ),
          ),
        ),
      ],
    );
  }
}
