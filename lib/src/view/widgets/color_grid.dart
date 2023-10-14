/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

class ColorGrid extends StatelessWidget {
  final void Function(Color color) onColorSelected;
  final Color? currentColor;

  const ColorGrid({Key? key, required this.onColorSelected, this.currentColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      shrinkWrap: true,
      children: [
        ...Colors.primaries,
        Colors.grey,
        Colors.white,
        ...Colors.accents,
      ]
          .map(
            (color) => RawMaterialButton(
              onPressed: () => onColorSelected(color),
              fillColor: color,
              shape: const CircleBorder(),
              child: currentColor?.value == color.value ? const Icon(Icons.check) : null,
            ),
          )
          .toList(),
    );
  }
}
