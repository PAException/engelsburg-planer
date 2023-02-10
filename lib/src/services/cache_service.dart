/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';
import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static SharedPreferences? _instance;

  /// Called on application initialize to init SharedPrefs and to set default values
  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
    await _setDefaultValues();
  }

  /// Set default values
  static Future<void> _setDefaultValues() async {
    //Set default values in map
    Map<String, dynamic> defaultValues = {
      "notification_settings_enabled": true,
      "notification_settings_articles": true,
      "notification_settings_substitutes_enabled": true,
      "notification_settings_substitutes_as_substitute_settings": true,
    };

    //Wait for all futures to complete while executing them asynchronously
    await Future.wait(defaultValues.mapToList<Future<void>>(set));
  }

  /// Set the value of a key
  //TODO further docs
  static Future<void> set(String key, dynamic value) async {
    //Checks to avoid errors
    if (value == null) return;
    if (_instance == null) return;

    //Check values and their type to save them
    if (value is bool) {
      await _instance!.setBool(key, value);
    } else if (value is int) {
      await _instance!.setInt(key, value);
    } else if (value is double) {
      await _instance!.setDouble(key, value);
    } else if (value is List) {
      await _instance!.setStringList(key, value.map((e) => e.toString()).toList());
    } else {
      await _instance!.setString(key, value.toString());
    }
  }

  /// Shorthand for set(key, jsonEncode(value)) with null check on value so no empty string is set
  static Future<void> setJson(String key, Object? value) async {
    if (value == null) return;

    return await set(key, jsonEncode(value));
  }

  /// Get a set value with type by its key
  ///
  /// Throws StateErrors on null instance, value not found and type error
  static T get<T>(String key) {
    if (_instance == null) {
      throw StateError("CacheService is not yet initialized.");
    }
    if (!_instance!.containsKey(key)) {
      throw StateError("CacheService could not find a value to that key.");
    }

    var get = _instance!.get(key);
    if (get is! T) {
      throw StateError("The specified type is not the one that was cached.");
    }

    return get;
  }

  /// Unlike get this function returns null on any error
  static T? getNullable<T>(String key) {
    if (_instance == null || !_instance!.containsKey(key)) return null;

    var get = _instance!.get(key);
    return get is T ? get : null;
  }

  /// Shorthand to get value that was json encoded (jsonDecode(get(key)))
  ///
  /// This function should be used when the value was also set via json
  static T getJson<T>(String key) => jsonDecode(get<String>(key));

  /// Shorthand for json encoded value and nullable get
  static T? getNullableJson<T>(String key) {
    String? json = getNullable<String>(key);
    if (json == null) return null;

    return jsonDecode(json);
  }

  /// Remove an entry of any kind associated with this key
  static Future<bool> remove(String key) async {
    if (_instance == null) return false;

    return _instance!.remove(key);
  }

  /// Call on request to append hash to it if cacheId specified
  static Request appendModifiedCheck(Request request) {
    //Return instance if no cacheId is specified
    if (request.cacheId == null) return request;

    //Try get hash, if null return non modified instance
    var hash = getNullable<String>("${request.cacheId!}_hash");
    if (hash == null) return request;

    //If hash is present return request with additional Hash-header
    request.headers["Hash"] = hash;
    return request;
  }

  /// Caches if data present and cacheId of request provided
  /// and returns cached data if response by API was NOT_MODIFIED
  ///
  /// Also sets cached data if response was timed out, error is not modified during this process
  /// so a timed out request is still recognizable
  static Future<ApiResponse<T>> handle<T>(
      Request request, ApiResponse<T> response, Parser<T> parse) async {
    //Return instance if no cacheId is specified
    if (request.cacheId == null) return response;

    if (response.dataPresent) {
      //Cache new data and hash if data present, return original response
      await set("${request.cacheId!}_hash", response.raw!.headers["hash"]);
      await setJson(request.cacheId!, response.data!);
    } else if (response.error?.isNotModified ?? false) {
      //If data wasn't modified get cached and return new ApiResponse with data and without error
      try {
        return ApiResponse<T>(response.raw, null, parse.call(getJson(request.cacheId!)));
      } on StateError {
        await remove(request.cacheId!);
      }
    } else if (response.error?.status == 999) {
      //Response timed out: ignore error but set data from cache
      dynamic json = getNullableJson(request.cacheId!);
      return ApiResponse<T>(response.raw, response.error, json != null ? parse.call(json) : null);
    }

    //Return original response if not a NOT_MODIFIED error was present
    return response;
  }
}
