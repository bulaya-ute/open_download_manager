import 'package:flutter/material.dart';

class PaddedColumn extends StatelessWidget {
  final List<Widget> children;
  final List<double> paddingLTRB; // [left, top, right, bottom]
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const PaddedColumn({
    super.key,
    this.children = const [],
    this.paddingLTRB = const [
      16,
      16,
      16,
      16,
    ], // default padding: left, top, right, bottom
    this.spacing = 0, // default no spacing
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  }) : assert(
         paddingLTRB.length == 4,
         "paddingLTRB must have 4 values: [left, top, right, bottom]",
       );

  @override
  Widget build(BuildContext context) {
    final spacedChildren = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i != children.length - 1 && spacing > 0) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        paddingLTRB[0],
        paddingLTRB[1],
        paddingLTRB[2],
        paddingLTRB[3],
      ),
      child: Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: spacedChildren,
      ),
    );
  }
}
