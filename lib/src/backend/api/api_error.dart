/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

/// Unify all api errors
@immutable
class ApiError {
  final int status;
  final String? messageKey;
  final String? extra;

  const ApiError(this.status, [this.messageKey, this.extra]);

  factory ApiError.fromJson(dynamic json) =>
      ApiError(json["status"], json["messageKey"], json["extra"]);

  /// Try parse an error by json
  /// If this fails take only the status code
  static ApiError tryParse(Response response) {
    try {
      return ApiError.fromJson(jsonDecode(response.body));
    } catch (_) {
      return ApiError(response.statusCode);
    }
  }

  void log() => debugPrint(toString());

  bool get isInvalidParam => status == 400 && messageKey == 'INVALID_PARAM';

  bool get isForbidden => status == 403 && messageKey == 'FORBIDDEN';

  bool get isNotFound => status == 404 && messageKey == 'NOT_FOUND';

  bool get isAlreadyExisting => status == 409 && messageKey == 'ALREADY_EXISTS';

  bool get isExpiredAccessToken => status == 400 && messageKey == 'EXPIRED' && extra == 'token';

  bool get isFailed => status == 400 && messageKey == "FAILED";

  bool get isNotModified => status == 304;

  bool get isTimedOut => status == 999;

  @override
  String toString() => "[API ERROR] => {status: $status, msgKey: $messageKey, extra: $extra}";
}
