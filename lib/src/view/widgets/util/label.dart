/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label(
    this.text, {
    super.key,
    required this.backgroundColor,
    this.foregroundColor,
  });

  final String text;
  final Color backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    Color color = foregroundColor ?? Colors.white;
    if (backgroundColor.computeLuminance() > 0.5) color = Colors.black;

    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
