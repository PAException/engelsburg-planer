/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:io';

import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/util/paging.dart';
import 'package:engelsburg_planer/src/backend/util/query.dart';
import 'package:engelsburg_planer/src/models/api/dto/update_notification_settings_dto.dart';
import 'package:engelsburg_planer/src/utils/firebase/analytics.dart';
import 'package:flutter/foundation.dart';

///
/// Host to send requests to
///
class Host {
  static bool enforceHttpForDebug = kDebugMode;

  //static String get api => kDebugMode ? debugApi : productionApi;
  static String get api => productionApi;

  static String get productionApi => "api.engelsburg-planer.de";

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

  static final SubstitutePath substitute = SubstitutePath();

  static final InfoPath info = InfoPath();

  static String get notificationSettings => "settings/notification";
}

class SubstitutePath {
  SubstitutePath();

  String get path => "substitute";

  String get keyHash => "$path/key";

  String get messages => "$path/message";
}

class InfoPath {
  InfoPath();

  String get path => "info";

  String get teacher => "$path/teacher";

  String get classes => "$path/classes";
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
    .cache("articles_${paging.page}_${paging.size}_$date")
    .analytics(Analytics.api.article);

RequestBuilder getArticle(int id) => Request.builder().https.api.get.path("${Path.article}/$id")
    .analytics(Analytics.api.article);

RequestBuilder getChangedArticles(List<String> hashes) =>
    Request.builder().https.api.patch.path(Path.article).jsonBody({"hashes": hashes})
        .analytics(Analytics.api.article);

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
        .cache("substitutes-$classes-$teacher")
        .analytics(Analytics.api.substitute);

RequestBuilder getSubstituteMessages(String substituteKey) => Request.builder()
    .https
    .api
    .get
    .path(Path.substitute.messages)
    .params(Query.substitutes(substituteKey))
    .cache("substitute_messages")
    .analytics(Analytics.api.substitute);

RequestBuilder getSubstituteKeyHash() =>
    Request.builder().https.api.get.path(Path.substitute.keyHash).cache("substitute_key_hash")
        .analytics(Analytics.api.substitute);

///
/// Information
///

RequestBuilder getTeacher(String substituteKey) => Request.builder()
    .https
    .api
    .get
    .path(Path.info.teacher)
    .params(Query.substitutes(substituteKey))
    .cache("info_teacher")
    .analytics(Analytics.api.info);

RequestBuilder getClasses(String substituteKey) => Request.builder()
    .https
    .api
    .get
    .path(Path.info.classes)
    .params(Query.substitutes(substituteKey))
    .cache("info_classes")
    .analytics(Analytics.api.info);

///
/// Notification
///
RequestBuilder updateNotificationSettings(String token, Iterable<String> priorityTopics) =>
    Request.builder()
        .https
        .api
        .post
        .path(Path.notificationSettings)
        .jsonBody(UpdateNotificationSettingsDTO(token: token, priorityTopics: priorityTopics))
        .analytics(Analytics.api.notificationSettings);

RequestBuilder deleteNotificationSettings(String token) =>
    Request.builder().https.api.delete.path(Path.notificationSettings).param("token", token)
        .analytics(Analytics.api.notificationSettings);

///
/// Other
///
RequestBuilder getEvents() => Request.builder().https.api.get.path(Path.event).cache("event")
    .analytics(Analytics.api.events);

RequestBuilder getCafeteria() =>
    Request.builder().https.api.get.path(Path.cafeteria).cache("cafeteria")
        .analytics(Analytics.api.cafeteria);

RequestBuilder getSolarSystem() =>
    Request.builder().https.api.get.path(Path.solarSystem).cache("solar_system")
        .analytics(Analytics.api.solar);
