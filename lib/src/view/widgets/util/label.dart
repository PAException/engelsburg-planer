/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label(
    this.text, {
    Key? key,
    required this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  final String text;
  final Color backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 4.0),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      );
}
