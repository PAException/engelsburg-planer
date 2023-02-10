/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/material.dart' hide Wrap;

/// Wrap widget builder with typed function
class Wrapper<T> extends StatelessWidget {
  final Wrap<T> wrap;
  final WrapBuilder<T> builder;

  const Wrapper({Key? key, required this.wrap, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) => builder.call(wrap.call(), context);
}
