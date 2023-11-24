/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request_service.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/util/query.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

typedef Parser<T> = T Function(dynamic json);

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

  /// Use https or http
  final bool https;

  /// Key to cache response of request
  final String? cacheId;

  final void Function(RequestAnalysis)? analytics;

  const Request(
    this.method,
    this.host,
    this.path,
    this.params,
    this.body,
    this.headers,
    this.https,
    this.cacheId,
    this.analytics,
  );

  /// Deserialize request
  factory Request.fromJson(dynamic json) => Request(
        httpMethodFromString(json["method"]),
        json["host"],
        json["path"],
        json["params"],
        json["body"],
        json["headers"],
        json["https"] == 1,
        json["cacheId"],
        json["analytics"],
      );

  /// Serialize request
  dynamic toJson() => {
        "method": method.toString(),
        "host": host,
        "path": path,
        "params": params,
        "body": body,
        "headers": headers,
        "https": https ? 1 : 0, //Sqflite doesn't support bool
        "cacheId": cacheId,
        "analytics": analytics,
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
  String? _cacheId;
  void Function(RequestAnalysis)? _analytics;

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
      _https,
      _cacheId,
      _analytics,
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

  /// Set callback to execute analytics call
  RequestBuilder analytics(void Function(RequestAnalysis) analytics) {
    _analytics = analytics;
    return this;
  }
}
