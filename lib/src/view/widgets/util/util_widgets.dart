import 'package:flutter/material.dart';

class NoOverScrollEffect extends ScrollBehavior {
  static Widget get(BuildContext context, Widget? child) => ScrollConfiguration(
        behavior: NoOverScrollEffect(),
        child: child!,
      );

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

class HeroText extends StatelessWidget {
  const HeroText({
    Key? key,
    required this.tag,
    required this.child,
  }) : super(key: key);

  final String tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
