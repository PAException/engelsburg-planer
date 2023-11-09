/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:hive/hive.dart';

typedef Parser<T> = T Function(dynamic json);

class AppPersistentData {
  static late final Box _data;

  static Future<void> initialize() async {
    _data = await Hive.openBox("app_persistent_data");
  }

  static T? get<T>(String key) {
    return _data.get(key) as T?;
  }

  static T? getJson<T>(String key, Parser<T> parser) {
    var data = _data.get(key);

    try {
      var json = jsonDecode(data);

      return parser.call(json);
    } catch (_) {
      return null;
    }
  }

  static void set(String key, dynamic value) {
    if (value == null) return;

    _data.put(key, value);
  }
  
  static void setJson(String key, dynamic value) {
    _data.put(key, jsonEncode(value));
  }

  static Future<void> delete(String key) => _data.delete(key);
}
