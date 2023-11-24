/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' hide Request;

typedef Parser<T> = T Function(dynamic json);

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

  Future<ApiResponse<T>> checkNotModified(Request request, Parser<T> parse) async {
    return this;

    /* //TODO
    //Return instance if no cacheId is specified
    if (request.cacheId == null) return this;

    if (dataPresent) {
      //Cache new data and hash if data present, return original response
      SessionPersistentData.keyed["${request.cacheId!}_hash"] = raw!.headers["hash"];
      await setJson(request.cacheId!, data!);
    } else if (error?.isNotModified ?? false) {
      //If data wasn't modified get cached and return new ApiResponse with data and without error
      try {
        return ApiResponse<T>(raw, null, parse.call(getJson(request.cacheId!)));
      } on StateError {
        await remove(request.cacheId!);
      }
    } else if (error?.status == 999) {
      //Response timed out: ignore error but set data from cache
      dynamic json = getNullableJson(request.cacheId!);
      return ApiResponse<T>(raw, error, json != null ? parse.call(json) : null);
    }

    //Return original response if not a NOT_MODIFIED error was present
    return this;
    */
  }

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
    return response.checkNotModified(request, parse);
  }
}
