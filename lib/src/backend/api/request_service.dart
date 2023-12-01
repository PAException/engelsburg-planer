/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/database/state/network_state.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

const Duration kTimeout = Duration(seconds: 5);

typedef Parser<T> = T Function(dynamic json);

/// Service to execute predefined api or plain requests
class RequestService {
  static const defaultApiHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json; charset=utf-8',
  };

  //TODO compute in isolate
  /// Executes request and parses response like given
  static Future<ApiResponse<T>> api<T>(Request request, Parser<T> parse) async =>
      (await execute(request)).asApiResponse(request, parse);

  /// Executes predefined GET, HEAD, POST, PUT, PATCH or DELETE http requests.
  ///
  /// GET or HEAD bodies will be ignored (RFC 7231)
  ///
  /// Will return empty body and status 0 after defined (default 5) timeout
  static Future<http.Response> execute(Request request, {Duration timeout = kTimeout}) async {
    var stopwatch = Stopwatch()..start();
    //Set network status loading
    globalContext().read<NetworkState>().update(NetworkStatus.loading);

    //Set default headers if api request
    if (request.host == Host.api) request.headers.addAll(defaultApiHeaders);
    //Set authorization header if request is an authenticated one

    //Append Hash-header if needed (modified check)
    request = appendModifiedCheck(request);
    var prepareTime = stopwatch.elapsedMilliseconds;

    //Execute request
    //TODO? create retry service? (callback?), exponential backoff?
    //On timeout or error return response with status = 999
    return _request(request)
        .onError((error, stackTrace) => http.Response("", 999))
        .timeout(timeout, onTimeout: () => http.Response("", 999))
        .then((response) {
      stopwatch.stop();

      RequestAnalysis analysis;
      if (response.statusCode == 999) {
        globalContext().read<NetworkState>().update(NetworkStatus.offline);

        analysis = RequestAnalysis.timedOut(prepareTime);
      } else {
        //If request wasn't timed out then set network status as online
        globalContext().read<NetworkState>().update(NetworkStatus.online);

        analysis = RequestAnalysis(
          prepareTime: prepareTime,
          responseTime: stopwatch.elapsedMilliseconds - prepareTime,
          responseSize: response.contentLength,
          timedOut: false,
        );
      }
      request.analytics?.call(analysis);

      return response;
    });
  }

  /// Performs actual request, declared by itself to add timeout
  static Future<http.Response> _request(Request request) async {
    //Get request info
    var uri = request.toUri();
    var headers = request.headers;
    var body = request.body;

    //Execute request
    switch (request.method) {
      case HttpMethod.get:
        return await http.get(uri, headers: headers); //GET
      case HttpMethod.head:
        return await http.head(uri, headers: headers); //HEAD
      case HttpMethod.post:
        return await http.post(uri, headers: headers, body: body); //POST
      case HttpMethod.put:
        return await http.put(uri, headers: headers, body: body); //PUT
      case HttpMethod.patch:
        return await http.patch(uri, headers: headers, body: body); //PATCH
      case HttpMethod.delete:
        return await http.delete(uri, headers: headers, body: body); //DELETE
    }
  }

  static Request appendModifiedCheck(Request request) {
    return request;

    /* //TODO
    //Return instance if no cacheId is specified
    if (request.cacheId == null) return request;

    //Try get hash, if null return non modified instance
    var hash = getNullable<String>("${request.cacheId!}_hash");
    if (hash == null) return request;

    //If hash is present return request with additional Hash-header
    request.headers["Hash"] = hash;
    return request;
    */
  }
}

@immutable
class RequestAnalysis {
  final int prepareTime;
  final int? responseTime;
  final int? responseSize;
  final bool timedOut;

  const RequestAnalysis({
    required this.prepareTime,
    required this.responseTime,
    required this.responseSize,
    required this.timedOut,
  }) : assert(timedOut || responseTime != null);

  const RequestAnalysis.timedOut(this.prepareTime)
      : timedOut = true,
        responseTime = null,
        responseSize = null;
}
