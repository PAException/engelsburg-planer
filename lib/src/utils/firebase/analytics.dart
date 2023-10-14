/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class Analytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static final DatabaseAnalytics database = DatabaseAnalytics(_analytics);
  static final IntroductionAnalytics introduction = IntroductionAnalytics(_analytics);
  static final UserAnalytics user = UserAnalytics(_analytics);
  static final InteractionAnalytics interaction = InteractionAnalytics(_analytics);
  static final ApiAnalytics api = ApiAnalytics(_analytics);

  static void initialize() => _analytics.setDefaultEventParameters({
      if (kDebugMode) "debug_mode": kDebugMode.toString(),
    });

  /// Called when the app starts building
  static void logAppOpen() => _analytics.logAppOpen();
}

//TODO more detailed information, e.g. request time, success, payload size, ...
/// Analytics label for api calls
class ApiAnalytics {
  final FirebaseAnalytics _analytics;

  ApiAnalytics(this._analytics);

  void _request(String type) => _analytics.logEvent(
      name: "api_request",
      parameters: {"type": type},
  );

  void article() => _request("article");

  void substitute() => _request("substitute");

  void notificationSettings() => _request("notification_settings");

  void cafeteria() => _request("cafeteria");

  void events() => _request("events");

  void solar() => _request("solar");
}

class InteractionAnalytics {
  final FirebaseAnalytics _analytics;

  InteractionAnalytics(this._analytics);

  late final ArticleAnalysis article = ArticleAnalysis(_analytics);

  /// Called everytime a new screen/page is shown
  /// --> most important are the base pages (navBar & drawer)
  void screen(String path) => _analytics.setCurrentScreen(screenName: path);
}

class ArticleAnalysis {
  final FirebaseAnalytics _analytics;

  ArticleAnalysis(this._analytics);

  /// Called everytime an article is selected
  void select(Article article) => _analytics.logSelectContent(
    contentType: "article",
    itemId: article.articleId.toString(),
  );

  /// Called if an article was saved
  /// --> should use [DelayedExecution]
  void save(Article article) => _analytics.logEvent(
    name: "article_save",
    parameters: {
      "articleId": article.articleId,
      "title": article.title,
    }
  );

  /// Called if an article was successfully shared
  void share(Article article, String method) => _analytics.logShare(
    contentType: "article",
    itemId: article.articleId.toString(),
    method: method,
  );
}

class UserAnalytics {
  final FirebaseAnalytics _analytics;

  UserAnalytics(this._analytics);

  /// Called everytime the app configuration was changed
  void setAppConfig(AppConfiguration config) {
    _type(config.userType);
    if (config.extra != null) _extra(config.extra!);
  }

  void _type(UserType type) => _analytics.setUserProperty(
    name: "user_type",
    value: type.name.toLowerCase(),
  );

  void _extra(String extra) => _analytics.setUserProperty(
    name: "user_extra",
    value: extra.toLowerCase(),
  );

  /// Called if the user was logged in
  void login([String? method]) => _analytics.logLogin(loginMethod: method);

  /// Called if the user was signed up
  void signUp(String method) => _analytics.logSignUp(signUpMethod: method);
}

class IntroductionAnalytics {
  final FirebaseAnalytics _analytics;

  IntroductionAnalytics(this._analytics);

  /// Called when the introduction page is first shown
  void begin() => _analytics.logTutorialBegin();

  /// Called when the introduction page is popped and the
  /// app is configured
  void complete() => _analytics.logTutorialComplete();
}

class DatabaseAnalytics {
  final FirebaseAnalytics _analytics;

  DatabaseAnalytics(this._analytics);

  void _log(String name, Storage storage) {
    String storageName = storage is FirestoreStorageImpl ? "firestore" : "local";

    _analytics.logEvent(
      name: name,
      parameters: {"storage": storageName},
    );
  }

  /// Called when a document was wrote to the database
  void write(Storage storage) => _log("database_write", storage);

  /// Called if a document was read from the database
  void read(Storage storage) => _log("database_read", storage);

  /// Called when a document was deleted in the database
  void delete(Storage storage) => _log("database_delete", storage);
}