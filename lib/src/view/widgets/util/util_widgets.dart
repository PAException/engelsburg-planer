import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
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

/// Indicates, that the widget should only be at max 500 in width, otherwise a modalBottomSheet will
/// be pushed.
abstract class CompactStatelessWidget extends StatelessWidget {
  const CompactStatelessWidget({super.key});
}

/// Indicates, that the widget should only be at max 500 in width, otherwise a modalBottomSheet will
/// be pushed.
abstract class CompactStatefulWidget extends StatefulWidget {
  const CompactStatefulWidget({super.key});
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

class OptionalHero extends StatelessWidget {
  const OptionalHero({Key? key, this.tag, required this.child}) : super(key: key);

  final String? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) => WrapIf(
        condition: tag != null,
        child: child,
        wrap: (child, context) => Hero(tag: tag!, child: child),
      );
}
