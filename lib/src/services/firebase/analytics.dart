/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/article.dart';
import 'package:engelsburg_planer/src/backend/api/request_service.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/analytics_interceptor.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class Analytics {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static final DatabaseAnalytics database = DatabaseAnalytics(_analytics);
  static final IntroductionAnalytics introduction =
      IntroductionAnalytics(_analytics);
  static final UserAnalytics user = UserAnalytics(_analytics);
  static final InteractionAnalytics interaction =
      InteractionAnalytics(_analytics);
  static final ApiAnalytics api = ApiAnalytics(_analytics);

  static void initialize() => _analytics.setDefaultEventParameters({
        if (kDebugMode) "debug_mode": kDebugMode.toString(),
      });

  /// Called when the app starts building
  static void logAppOpen() => _analytics.logAppOpen();
}

/// Analytics label for api calls
class ApiAnalytics {
  final FirebaseAnalytics _analytics;

  ApiAnalytics(this._analytics);

  void _request(String type, RequestAnalysis analysis) => _analytics.logEvent(
        name: "api_request",
        parameters: {
          "api_request_type": type,
          "api_request_prepare_time": analysis.prepareTime,
          "api_request_timed_out": analysis.timedOut.toString(),
          if (analysis.responseTime != null)
            "api_response_time": analysis.responseTime,
          if (analysis.responseSize != null)
          "api_response_size": analysis.responseSize,
        },
      );

  void article(RequestAnalysis analysis) => _request("article", analysis);

  void substitute(RequestAnalysis analysis) => _request("substitute", analysis);

  void notificationSettings(RequestAnalysis analysis) =>
      _request("notification_settings", analysis);

  void cafeteria(RequestAnalysis analysis) => _request("cafeteria", analysis);

  void events(RequestAnalysis analysis) => _request("events", analysis);

  void solar(RequestAnalysis analysis) => _request("solar", analysis);

  void info(RequestAnalysis analysis) => _request("info", analysis);
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
  void save(Article article) =>
      _analytics.logEvent(name: "article_save", parameters: {
        "article_id": article.articleId,
        "article_title": article.title,
      });

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

  void _log(String type, String storage) => _analytics.logEvent(
      name: type,
      parameters: {"database_storage": storage},
    );

  /// Called when a document was wrote to the database
  void write(String storage) => _log("database_write", storage);

  /// Called if a document was read from the database
  void read(String storage) => _log("database_read", storage);

  /// Called when a document was deleted in the database
  void delete(String storage) => _log("database_delete", storage);
}

class GoogleAnalyticsInterceptor extends AnalyticsInterceptor {
  GoogleAnalyticsInterceptor(String label) : super(
    onRead: (_) => Analytics.database.read(label),
    onWrite: (_) => Analytics.database.write(label),
    onDelete: (_) => Analytics.database.delete(label),
  );
}
