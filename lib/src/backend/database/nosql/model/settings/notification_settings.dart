/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationSettings {
  bool _enabled;
  Set<String> _topics;
  Set<String> _priorityTopics;
  bool _substitute;


  NotificationSettings(
    this._enabled,
    this._topics,
    this._priorityTopics,
    this._substitute,
  );

  static DocumentReference<NotificationSettings> ref() =>
      const DocumentReference<NotificationSettings>("notification_settings", NotificationSettings.fromJson);

  NotificationSettings.all([bool? on])
      : _enabled = NotificationHelper.isAuthorized,
        _topics = {},
        _priorityTopics = NotificationHelper.isAuthorized ? {
          "article"
        } : {},
        _substitute = NotificationHelper.isAuthorized;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      json.isEmpty ? NotificationSettings.all() : NotificationSettings(
    json["enabled"],
    json["topics"],
    json["priorityTopics"],
    json["substitute"],
  );

  Map<String, dynamic> toJson() => {
    "enabled": _enabled,
    "topics": _topics,
    "priorityTopics": _priorityTopics,
  };
}

extension NotificationHelper on NotificationSettings {
  static final fcm = FirebaseMessaging.instance;
  static late AuthorizationStatus _authorizationStatus;

  static bool get isAuthorized => _authorizationStatus != AuthorizationStatus.denied;

  static Future<void> init() async {
    await fcm.setAutoInitEnabled(true);

    //Get notification settings from firebase,
    // ask for permission if state is not determined yet
    var settings = await fcm.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await fcm.requestPermission(carPlay: true);
    }

    //Update auth status
    _authorizationStatus = settings.authorizationStatus;
  }

  /// Subscribe to a topic via FCM
  /// Function calls will automatically be delayed to prevent spamming.
  static void topicSubscription(String topic, bool subscribe) {
    DelayedExecution.exec(
      "topic_subscription_$topic",
      () {
        if (subscribe) return fcm.subscribeToTopic(topic);

        return fcm.unsubscribeFromTopic(topic);
      },
    );
  }

  /// Subscribe to a priority topic via the API.
  /// Function calls will automatically be delayed to prevent spamming.
  static void updatePriorityTopics(Iterable<String> topics) async {
    DelayedExecution.exec(
      "update_priority_topics",
      () async {
        String? token;
        try {
          //Get FCM token
          token = await fcm.getToken();

          //Make request to API
          if (topics.isEmpty) {
            deleteNotificationSettings(token!).build().api(ignore);
          } else {
            updateNotificationSettings(token!, topics).build().api(ignore);
          }
        } catch (exception, stack) {
          if (!kDebugMode) {
            FirebaseCrashlytics.instance.recordError(
              exception,
              stack,
              reason: token == null
                  ? "Couldn't get FCM Token to update notification settings"
                  : "Couldn't update notification settings",
            );
          } else {
            rethrow;
          }
        }
      },
    );
  }

  bool get enabled => _enabled;

  /// Must be called when the notification settings switch has changed.
  /// This function will count in the authorization status of FCM to decide if
  /// the switch can be enabled or not.
  void setEnabled(bool value) async {
    //If value is to be enabled
    if (value && _authorizationStatus != AuthorizationStatus.authorized) {
      var settings = await fcm.requestPermission(carPlay: true);
      _authorizationStatus = settings.authorizationStatus;

      if (!isAuthorized) return;
    }

    _enableOrDisable(_enabled = value);
  }

  /// Must be called if notifications in general are enabled or disabled.
  /// If disabled, all sub-notification settings will also be disabled.
  /// If enabled, they will be set to their value before.
  void _enableOrDisable(bool value) {
    if (_substitute) {
      setSubstitute(_substitute);
    } else {
      updatePriorityTopics(value ? _priorityTopics : {});
    }

    for (var topic in _topics) {
      topicSubscription(topic, value);
    }
  }

  bool get substitute => _substitute;

  /// Sets the substitute settings notification value.
  /// If false no priority topics of substitute settings will be get and
  /// a request is only made with the current priority topics.
  /// If true priority topics if substitute settings will be get and a
  /// request us made with the current priority topics and those from the
  /// substitute settings.
  void setSubstitute(bool value) async {
    _substitute = value;
    if (!value) return updatePriorityTopics(_priorityTopics);

    var settings = await SubstituteSettings.ref().offline.load();
    var substituteTopics = await settings.priorityTopics();

    updatePriorityTopics({
      ..._priorityTopics,
      ...substituteTopics
    });
  }

  /// Refreshes substitute settings
  void updateSubstituteSettings() => setSubstitute(_substitute);

  bool get article => _priorityTopics.contains("article");

  set article(bool value) => updatePriorityTopics(_priorityTopics..add("article"));
}
