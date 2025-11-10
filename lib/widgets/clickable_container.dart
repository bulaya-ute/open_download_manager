import 'package:flutter/material.dart';

class ClickableContainer extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color borderColor;
  final double? height;

  const ClickableContainer({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 0,
    this.padding,
    this.backgroundColor,
    this.borderColor = Colors.transparent, // Default transparent border
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(borderRadius);

    return SizedBox(
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,

          child: Ink(
            // height: height,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.transparent,

              borderRadius: radius,
              border: Border.all(color: borderColor), // Add border
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
