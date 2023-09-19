/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:io';

import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/util/paging.dart';
import 'package:engelsburg_planer/src/backend/util/query.dart';
import 'package:engelsburg_planer/src/models/api/dto/update_notification_settings_dto.dart';
import 'package:flutter/foundation.dart';

///
/// Host to send requests to
///
class Host {
  static bool enforceHttpForDebug = kDebugMode;

  static String get api => kDebugMode ? debugApi : productionApi;

  static String get productionApi => "engelsburg-api.de";

  static String get debugApi =>
      "${Platform.isIOS || Platform.isAndroid ? "10.0.2.2" : "localhost"}:80";
}

///
/// Path of requests
///
class Path {
  static String get article => "article";

  static String get event => "event";

  static String get cafeteria => "cafeteria";

  static String get solarSystem => "solar_system";

  static SubstitutePath get substitute => SubstitutePath();

  static String get notificationSettings => "settings/notification";
}

class SubstitutePath {
  SubstitutePath();

  String get path => "substitute";

  String get keyHash => "$path/key";

  String get messages => "$path/message";
}

///
///
/// Requests
///
///

///
/// Articles
///
RequestBuilder getArticles({int? date, Paging paging = const Paging(0, 20)}) => Request.builder()
    .https
    .api
    .get
    .path(Path.article)
    .params(Query.paging(paging) + Query.date(date))
    .cache("articles");

RequestBuilder getArticle(int id) => Request.builder().https.api.get.path("${Path.article}/$id");

RequestBuilder getChangedArticles(List<String> hashes) =>
    Request.builder().https.api.patch.path(Path.article).jsonBody({"hashes": hashes});

///
/// Substitutes
///
RequestBuilder getSubstitutes(
  String substituteKey, {
  List<String>? classes,
  List<String>? teacher,
}) =>
    Request.builder()
        .https
        .api
        .get
        .path(Path.substitute.path)
        .params(Query.substitutes(
          substituteKey,
          classes: classes,
          teacher: teacher,
        ))
        .cache("substitutes-$classes-$teacher");

RequestBuilder getSubstituteMessages(String substituteKey) => Request.builder()
    .https
    .api
    .get
    .path(Path.substitute.messages)
    .params(Query.substitutes(substituteKey))
    .cache("substitute_messages");

RequestBuilder getSubstituteKeyHash() =>
    Request.builder().https.api.get.path(Path.substitute.keyHash).cache("substitute_key_hash");

///
/// Notification
///
RequestBuilder updateNotificationSettings(String token, List<String> priorityTopics) =>
    Request.builder()
        .https
        .api
        .post
        .path(Path.notificationSettings)
        .jsonBody(UpdateNotificationSettingsDTO(token: token, priorityTopics: priorityTopics));

RequestBuilder deleteNotificationSettings(String token) =>
    Request.builder().https.api.delete.path(Path.notificationSettings).param("token", token);

///
/// Other
///
RequestBuilder getEvents() => Request.builder().https.api.get.path(Path.event).cache("event");

RequestBuilder getCafeteria() =>
    Request.builder().https.api.get.path(Path.cafeteria).cache("cafeteria");

RequestBuilder getSolarSystem() =>
    Request.builder().https.api.get.path(Path.solarSystem).cache("solar_system");
