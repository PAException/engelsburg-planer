/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request_service.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/util/query.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

enum HttpMethod { get, head, post, put, patch, delete }

Parser ignore = (json) {};
Parser<dynamic> json = (json) => json;

HttpMethod httpMethodFromString(String method) {
  switch (method) {
    case "get":
      return HttpMethod.get;
    case "head":
      return HttpMethod.head;
    case "put":
      return HttpMethod.put;
    case "post":
      return HttpMethod.post;
    case "patch":
      return HttpMethod.patch;
    case "delete":
      return HttpMethod.delete;
    default:
      return HttpMethod.get;
  }
}

/// Immutable request to be executed
@immutable
class Request {
  /// Standard http method (GET, POST, ...)
  final HttpMethod method;

  /// Host to send request to (e.g. google.com)
  /// Port can also be specified (e.g. google.com:80)
  final String host;

  /// Path of the target
  /// e.g. if target is "google.com/search" then this field must be "search"
  final String path;

  /// Params to append to the request uri
  final Query params;

  /// Body to send with the request; not available for GET
  final Object? body;

  /// Headers of request
  final Map<String, String> headers;

  /// Whether this is an authenticated api request or not; forces https=true and host=Host.api
  final bool authenticated;

  /// Use https or http
  final bool https;

  /// Key to cache response of request
  final String? cacheId;

  const Request(
    this.method,
    this.host,
    this.path,
    this.params,
    this.body,
    this.headers,
    this.authenticated,
    this.https,
    this.cacheId,
  );

  /// Deserialize request
  factory Request.fromJson(dynamic json) => Request(
        httpMethodFromString(json["method"]),
        json["host"],
        json["path"],
        json["params"],
        json["body"],
        json["headers"],
        json["authenticated"] == 1,
        json["https"] == 1,
        json["cacheId"],
      );

  /// Serialize request
  dynamic toJson() => {
        "method": method.toString(),
        "host": host,
        "path": path,
        "params": params,
        "body": body,
        "headers": headers,
        "authenticated": authenticated ? 1 : 0, //Sqflite doesn't support bool
        "https": https ? 1 : 0,
        "cacheId": cacheId,
      };

  /// Get RequestBuilder
  static RequestBuilder builder() => RequestBuilder._();

  /// Execute Request
  Future<Response> perform() => RequestService.execute(this);

  /// Execute Request and retrieve ApiResponse<T>
  Future<ApiResponse<T>> api<T>(Parser<T> parse) => RequestService.api(this, parse);

  /// Parse the uri-properties of the request to an uri
  Uri toUri() {
    String prefix = https ? "https" : "http";
    String query = params.get;

    return Uri.parse("$prefix://$host/$path$query");
  }
}

/// Helper class to build a [Request] with some shorthands
class RequestBuilder {
  RequestBuilder._();

  HttpMethod? _method;
  String? _host;
  String? _path;
  Query _params = Query({});
  Object? _body;
  Map<String, String> _headers = {};
  bool _https = false;
  bool _authenticated = false;
  String? _cacheId;

  /// Build the actual request
  Request build() {
    if (_method == null || _host == null) {
      throw FlutterError("Cannot build request without a method or an url");
    }
    _path ??= "";

    return Request(
      _method!,
      _host!,
      _path!,
      _params,
      _body,
      _headers,
      _authenticated,
      _https,
      _cacheId,
    );
  }

  /// Set http methods
  RequestBuilder method(HttpMethod method) {
    _method = method;
    return this;
  }

  /// Shorthands to set http method
  RequestBuilder get get => method(HttpMethod.get);

  RequestBuilder get head => method(HttpMethod.head);

  RequestBuilder get post => method(HttpMethod.post);

  RequestBuilder get patch => method(HttpMethod.patch);

  RequestBuilder get put => method(HttpMethod.put);

  RequestBuilder get delete => method(HttpMethod.delete);

  /// Set host
  RequestBuilder host(String host) {
    _host = host;
    return this;
  }

  /// Set default api host
  RequestBuilder get api => host(Host.api);

  /// Set path of request
  RequestBuilder path(String? path) {
    _path = path;
    return this;
  }

  /// Set params
  RequestBuilder params(Query params) {
    _params = params;
    return this;
  }

  RequestBuilder param(String key, dynamic value) {
    _params[key] = value;
    return this;
  }

  /// Set body
  RequestBuilder body(Object? body) {
    _body = body;
    return this;
  }

  RequestBuilder jsonBody(Object toJson) => body(jsonEncode(toJson));

  /// Set headers
  RequestBuilder headers(Map<String, String> headers) {
    _headers = headers;
    return this;
  }

  RequestBuilder header(String key, String value) {
    _headers[key] = value;
    return this;
  }

  /// Set the request as an authenticated api request
  RequestBuilder get authenticated {
    _authenticated = true;
    if (!Host.enforceHttpForDebug) _https = true; //Enforce https on authenticated
    return api; //Set api url
  }

  /// Set https
  RequestBuilder get https {
    if (!Host.enforceHttpForDebug) _https = true;
    return this;
  }

  /// Set cacheId
  RequestBuilder cache(String? cacheId) {
    _cacheId = cacheId;
    return this;
  }
}
