/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/constants.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 1});

  final double size;

  @override
  Widget build(BuildContext context) {
    return WrapIf(
      condition: Theme.of(context).brightness == Brightness.dark,
      wrap: (child, context) => CircleAvatar(
        radius: 30 * size,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: child,
        ),
      ),
      child: Image.asset(AssetPaths.appLogo, height: 60 * size),
    );
  }
}

