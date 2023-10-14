/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';

class AnimatedAppName extends StatefulWidget {
  const AnimatedAppName({
    Key? key,
    this.textStyle = const TextStyle(fontSize: 24),
    this.iconSize = 80,
    this.curve = Curves.fastOutSlowIn,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  final TextStyle textStyle;
  final double iconSize;

  ///Animation settings
  final Curve curve;
  final Duration duration;

  @override
  AnimatedAppNameState createState() => AnimatedAppNameState();
}

class AnimatedAppNameState extends State<AnimatedAppName> with SingleTickerProviderStateMixin {
  AnimationController? controller;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    animation = CurvedAnimation(parent: controller!, curve: widget.curve)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller?.forward();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Image(
          image: const AssetImage(AssetPaths.appLogo),
          width: widget.iconSize,
        ),
        SizeTransition(
          sizeFactor: animation!,
          axis: Axis.horizontal,
          axisAlignment: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: Text(context.l10n.appTitle, style: widget.textStyle),
            ),
          ),
        ),
      ],
    );
  }
}
