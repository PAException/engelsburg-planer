/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:html_unescape/html_unescape.dart';

/// If in debugMode prints current stack
void printCurrentStack() {
  if (!kDebugMode) return;

  try {
    throw Error();
  } catch (_, stack) {
    debugPrintStack(stackTrace: stack);
  }
}

String unescapeHtml(text) => HtmlUnescape()
    .convert(text)
    .replaceAll(RegExp(r'\n+'), ' ')
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .trim();

class DelayedExecution {
  static final Map<String, Timer> _execs = {};

  static void exec(String key, FutureOr<void> Function() exec, [Duration delay = const Duration(seconds: 10)]) async {
    _execs[key]?.cancel();
    _execs[key] = Timer(delay, exec);
  }
}
