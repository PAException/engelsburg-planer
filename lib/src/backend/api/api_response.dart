/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' hide Request;

Future? _lock;

/// This function does the actual refresh of the access token. It gets the corresponding refresh
/// token via the [UserState] from the global context and performs the request.
/// If the response includes data update the old auth info, if it fails force a re-login of the
/// user.
/*
Future refreshAccessToken() async {
  var user = globalContext().read<UserState>();

  //Execute request and parse response
  var res = await rq.refreshTokens(user.refreshToken!).build().api(AuthResponseDTO.fromJson);

  if (res.dataPresent) {
    user.update(res.data!);
  } else {
    user.forceReLogin();
  }
}
*/

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

  /// Checks if the response is an error response from the api because of an expired access token.
  /// If so this function tries to request a new one. To avoid many refresh attempts this function
  /// locks to only let the first failed request try a refresh attempt.
  Future<ApiResponse<T>> checkExpiredAccessToken(Request request, Parser<T> parse) async {
    if (error?.isExpiredAccessToken ?? false) {
      //TODO must be logged in
      //Lock refresh attempt
      if (_lock != null) {
        //Wait for an active refresh attempt
        await _lock;
      } else {
        //If no attempt has started try refreshing
        //_lock = refreshAccessToken();
        await _lock;
        _lock = null;
      }

      return await request.api(parse);
    }

    //If response is not caused by an expired access token return this instance
    return this;
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

    //Check for expired access token
    response = await response.checkExpiredAccessToken(request, parse);

    //Check for not modified error and cached data
    response = await CacheService.handle<T>(request, response, parse);

    //Return final response
    return response;
  }
}
