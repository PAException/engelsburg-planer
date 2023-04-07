/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/db/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OnlineNotificationSettings extends OnlineDocument<NotificationSettings> {
  OnlineNotificationSettings()
      : super(documentReference: doc, fromJson: NotificationSettings.fromJson);

  static DocumentReference<Map<String, dynamic>> doc() =>
      FirebaseFirestore.instance.collection("subjects").doc(FirebaseAuth.instance.currentUser!.uid);
}

class OfflineNotificationSettings extends OfflineDocument<NotificationSettings> {
  OfflineNotificationSettings()
      : super(key: "notification_settings", fromJson: NotificationSettings.fromJson);
}

class NotificationSettings {
  bool _enabled;
  bool _article;
  bool _substitute;

  NotificationSettings(
    this._enabled,
    this._article,
    this._substitute,
  );

  static Document<NotificationSettings> get([bool online = storeOnline]) =>
      online ? OnlineNotificationSettings() : OfflineNotificationSettings();

  NotificationSettings.all([bool? on])
      : _enabled = NotificationSettingsHelper.isAuthorized,
        _article = NotificationSettingsHelper.isAuthorized,
        _substitute = NotificationSettingsHelper.isAuthorized;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) => json.isEmpty
      ? NotificationSettings.all()
      : NotificationSettings(json["enabled"], json["article"], json["substitute"]);

  Map<String, dynamic> toJson() =>
      {"enabled": _enabled, "article": _article, "substitute": _substitute};
}

extension NotificationSettingsHelper on NotificationSettings {
  static final fcm = FirebaseMessaging.instance;
  static late AuthorizationStatus authorizationStatus;

  static bool get isAuthorized => authorizationStatus == AuthorizationStatus.authorized;

  static Future<void> init() async {
    var settings = await fcm.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await fcm.requestPermission(carPlay: true);
    }

    authorizationStatus = settings.authorizationStatus;
    if (isAuthorized) {
      var notificationSettings = await NotificationSettings.get().load();
      notificationSettings
        ..enabled = true
        ..article = true
        ..substitute = true;
    }
  }

  static void subscription(String topic, bool subscribe) {
    if (subscribe) {
      fcm.subscribeToTopic(topic);
    } else {
      fcm.unsubscribeFromTopic(topic);
    }
  }

  void _enableOrDisable(bool value) {
    DelayedExecution.exec("notification_settings", () {
      article = value ? _article : value;
      substitute = value ? _substitute : value;
    });
  }

  set enabled(bool value) {
    if (!value || authorizationStatus == AuthorizationStatus.authorized) {
      _enableOrDisable(_enabled = value);
      return;
    }

    fcm.requestPermission(carPlay: true).then((settings) {
      authorizationStatus = settings.authorizationStatus;
      if (authorizationStatus == AuthorizationStatus.authorized) _enableOrDisable(_enabled = value);
    });
  }

  set article(bool value) {
    _article = value;
    if (!enabled) return;

    DelayedExecution.exec("article_notification", () => subscription("article", value));
  }

  set substitute(bool value) {
    _substitute = value;
    if (!enabled) return;

    DelayedExecution.exec("update_notification_settings", () {
      SubstituteSettings.get().load().then((settings) async {
        var token = (await fcm.getToken())!;
        if (!value) {
          subscription("substitute", value);
          deleteNotificationSettings(token).build().api(ignore);
        } else {
          var topics = await settings.priorityTopics();

          if (topics.isEmpty) {
            deleteNotificationSettings(token).build().api(ignore);
          } else {
            subscription("substitute", false);
            updateNotificationSettings(token, topics).build().api(ignore);
          }
        }
      });
    });
  }

  void updateSubstitutes() => substitute = _substitute;

  bool get enabled => _enabled;

  bool get article => _article;

  bool get substitute => _substitute;
}
