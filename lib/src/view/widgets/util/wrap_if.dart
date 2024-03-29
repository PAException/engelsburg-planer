/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/widgets.dart';

class WrapIf extends StatelessWidget {
  final bool condition;
  final Widget Function(Widget child, BuildContext context) wrap;
  final Widget child;

  const WrapIf({
    super.key,
    required this.condition,
    required this.wrap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) return wrap.call(child, context);

    return child;
  }
}
