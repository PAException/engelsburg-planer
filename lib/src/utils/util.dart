/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';

typedef AnimationFunction = AnimatedWidget Function(Animation<double> animation, Widget child);

class HtmlUtils {
  static String unescape(text) => HtmlUnescape()
      .convert(text)
      // remove all newlines
      .replaceAll(RegExp(r'[\n]+'), ' ')
      // remove all html tags
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .trim();
}

BuildContext globalContext() => GlobalContext.key.currentContext ?? GlobalContext.firstContext!;

class GlobalContext {
  static final key = GlobalKey<NavigatorState>();
  static BuildContext? firstContext;
}

class Animations {
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

  static ScaleTransition easeInScaleQuadSize(Animation<double> animation, Widget child) =>
      ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        ),
        child: SizeTransition(
          sizeFactor: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInQuad,
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
