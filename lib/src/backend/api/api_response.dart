/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' hide Request;

/// Handle http responses of api
@immutable
class ApiResponse<T> {
  final Response? raw;
  final ApiError? error;
  final T? data;

  const ApiResponse(
    this.raw,
    this.error,
    this.data,
  );

  const ApiResponse.error(this.error)
      : raw = null,
        data = null;

  bool get errorPresent => error != null;

  bool get dataPresent => data != null;

  bool get errorNotPresent => error == null;

  bool get dataNotPresent => data == null;

  @override
  String toString() {
    return 'ApiResponse{raw: $raw, error: $error, data: $data}';
  }
}

extension ResponseExtension on Response {
  /// Parse ApiResponse<T> from http response
  Future<ApiResponse<T>> asApiResponse<T>(Request request, Parser<T> parse) async {
    T? data;
    ApiError? error;

    //Parse optional data or error
    if (!statusCode.toString().startsWith("2")) {
      error = ApiError.tryParse(this);
    } else if (body.isNotEmpty) {
      data = parse(jsonDecode(body));
    }

    //Create first instance of api response
    var response = ApiResponse(this, error, data);

    //Log response
    if (kDebugMode) {
      String method = "[${request.method.toString().split(".")[1].toUpperCase()}] ";
      String uri = request.toUri().toString();
      String cacheKey = request.cacheId != null ? "cacheKey: ${request.cacheId}" : "no caching";
      String cached = error?.isNotModified ?? false ? "[CACHED]" : "";
      String hash = response.raw != null ? "hash: ${response.raw!.headers["hash"]}" : "";

      print("API Request: $method $uri ($cacheKey $cached; $hash)");
      if (!(error?.isNotModified ?? false)) error?.log();
    }

    //Check for not modified error and cached data
    response = await CacheService.handle<T>(request, response, parse);

    //Return final response
    return response;
  }
}
