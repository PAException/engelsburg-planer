/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:http/http.dart' as http;

const Duration kTimeout = Duration(seconds: 5);

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
    //Set network status loading
    globalContext().loading();

    //Set default headers if api request
    if (request.host == Host.api) request.headers.addAll(defaultApiHeaders);
    //Set authorization header if request is an authenticated one
    if (request.authenticated) {
      assert(globalContext().loggedIn);
      //request.headers["Authorization"] = globalContext().read<UserState>().accessToken!;
    }

    //Append Hash-header if needed (modified check)
    request = CacheService.appendModifiedCheck(request);

    //Execute request
    return _request(request).timeout(timeout, onTimeout: () {
      //On timeout set network status as offline and return response with status = 999
      globalContext().offline();
      //TODO? create retry service? (callback?)
      return http.Response("", 999);
    }).then((response) {
      //If request wasn't timed out then set network status as online
      if (response.statusCode != 999) {
        globalContext().online();
      }

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
}
