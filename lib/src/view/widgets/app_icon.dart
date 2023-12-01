/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/constants.dart';
import 'package:flutter/material.dart';

class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 1});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * size),
        boxShadow: [
          if (Theme.of(context).brightness == Brightness.light)
            const BoxShadow(
              color: Colors.grey,
              offset: Offset(2.0, 2.0),
              blurRadius: 4.0,
            ),
        ],
      ),
      child: Image.asset(AssetPaths.appLogo, height: 60 * size),
    );
  }
}
