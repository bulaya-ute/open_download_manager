import 'package:flutter/material.dart';

class OptionSelector extends StatelessWidget {
  final String value;
  final List<String> options;
  final void Function(String newValue) onChanged;
  const OptionSelector({super.key, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        border: BoxBorder.all(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((element) => _buildTab(context, element)).toList(),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String title, ) {
    final isActive = value == title;

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return GestureDetector(
      onTap: isActive
        ? null
        : () => onChanged(title),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isActive
                ? Theme.of(context).scaffoldBackgroundColor
                : Colors.transparent,
            // border: Border.all(
            //   color: Theme.of(context).colorScheme.onSurface.withAlpha(25)
            //   ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? onSurface : onSurface.withAlpha(200),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

}
