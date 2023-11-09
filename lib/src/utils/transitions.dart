/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

class Transitions {
  static FadeTransition easeFade(Animation<double> animation, Widget child) => FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.ease,
    ),
    child: child,
  );

  static ScaleTransition easeOutScaleQuadSize(Animation<double> animation, Widget child) =>
      ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuad,
          ),
          child: child,
        ),
      );

  static SizeTransition easeInOutSineSizeEaseInSineScale(
      Animation<double> animation, Widget child) =>
      SizeTransition(
        sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOutSine),
        child: ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeInSine),
          child: child,
        ),
      );

  static FadeTransition easeFadeScaleSize(Animation<double> animation, Widget child) => easeFade(
    animation,
    SizeTransition(
      sizeFactor: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    ),
  );
}
