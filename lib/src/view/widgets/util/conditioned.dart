/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

/// Widget to wrap an if statement/condition.
///
/// If condition is true this widget returns the given child.
/// If condition is false this widget returns the otherwise widget, if not specified it will
/// return an empty container.
class Conditioned extends StatelessWidget {
  final bool condition;
  final Widget child;
  final Widget? otherwise;

  const Conditioned({
    super.key,
    required this.condition,
    required this.child,
    this.otherwise,
  });

  @override
  Widget build(BuildContext context) => (condition ? child : otherwise) ?? Container();
}
