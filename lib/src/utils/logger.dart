// ignore_for_file: avoid_print

/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:flutter/foundation.dart';

@immutable
class Level {
  final int value;
  final String name;

  const Level(this.value, this.name);

  static const Level fine = Level(100, "fine");
  static const Level trace = Level(200, "trace");
  static const Level debug = Level(300, "debug");
  static const Level info = Level(400, "info");
  static const Level warning = Level(500, "warning");
  static const Level error = Level(600, "error");
  static const Level fatal = Level(700, "fatal");
}

class Logger<T> {
  static final Map<Type, Logger<dynamic>> _loggers = {};
  static Level rootLevel = debugMode ? Level.debug : Level.info;
  static bool debugMode = kDebugMode;
  static bool analytics = !kDebugMode;

  static Logger<T> forType<T>([Level? level]) {
    if (!_loggers.containsKey(T)) {
      _loggers[T] = Logger<T>(level ?? rootLevel);
    } else if (level != null) {
      _loggers[T]!.level = level;
    }

    return _loggers[T] as Logger<T>;
  }

  void log(String msg, Level level) {
    if (level.value < this.level.value) return;

    String composed = "[$T] ${level.name.toUpperCase()}: $msg";
    if (debugMode) print(composed);
    if (analytics) Crashlytics.log(composed);
  }

  void fine(String msg) => log(msg, Level.fine);
  void trace(String msg) => log(msg, Level.trace);
  void debug(String msg) => log(msg, Level.debug);
  void info(String msg) => log(msg, Level.info);
  void warning(String msg) => log(msg, Level.warning);
  void error(String msg) => log(msg, Level.error);
  void fatal(String msg) => log(msg, Level.fatal);

  Logger(this.level);

  Level level;
}

mixin Logs<T> {
  Logger<T> get logger => Logger.forType<T>();
}
