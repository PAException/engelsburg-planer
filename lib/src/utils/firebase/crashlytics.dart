/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Crashlytics {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static void initialize() => _crashlytics.sendUnsentReports();

  /// Log an error message to extend the crash report
  static void log(String msg) => _crashlytics.log(msg);

  /// Set a custom key-value-pair to extend the logs and errors.
  /// Value will tried to be encoded to json,
  /// otherwise the toString() value is used.
  static void set(String key, dynamic value) {
    String? data;
    try {
      data = jsonEncode(value);
    } catch (_) {}
    data ??= value.toString();

    _crashlytics.setCustomKey(key, data);
  }
}
