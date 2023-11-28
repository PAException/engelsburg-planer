/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:io';
import 'dart:math';

import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:engelsburg_planer/src/services/firebase/firebase_options.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Util class for all firebase initializations and configurations.
class FirebaseConfig {
  /// Initializes every used firebase service
  static Future<void> initialize() async {
    //Init the core firebaseApp
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
    );

    Crashlytics.log("Initializing firebase services");

    //Init sub services
    Analytics.initialize();
    if (!kDebugMode) Crashlytics.initialize();
    await initializeRemoteConfig();
  }

  /// Initialize FCM - initialNotification, tokenRefresh action
  static void initializeFCM() async {
    //Check if app was opened via a notification
    FirebaseMessaging.instance
        .getInitialMessage()
        .then(handleOpenedRemoteMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleOpenedRemoteMessage);

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
    );

    final localNotifications = FlutterLocalNotificationsPlugin();
    localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings("mipmap/ic_launcher"),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: handleLocalOpenedNotification,
      onDidReceiveBackgroundNotificationResponse: handleLocalOpenedNotification,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Crashlytics.log("Received notification while the app was opened");
      //On IOS the notification is also displayed when the app is opened
      if (Platform.isIOS) return;

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: android?.smallIcon,
            ),
          ),
          payload: message.data["link"],
        );
      }
    });

    //Push changes to server if token changes
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      var substituteSettings = await SubstituteSettings.ref().offline.load();

      updateNotificationSettings(
        token,
        await substituteSettings.priorityTopics(),
      ).build().api(ignore);
    });
  }

  static void handleLocalOpenedNotification(NotificationResponse details) =>
      handleOpenedRemoteMessage(RemoteMessage(data: {"link": details.payload}));

  static void handleOpenedRemoteMessage(RemoteMessage? message) {
    if (message == null) return;
    Crashlytics.log("Handling user click on notification");
    Crashlytics.set("notification_data", message.data);
    if (message.data.isNotEmpty) {
      String? link = message.data["link"];
      if (link != null && link.isNotEmpty) {
        globalContext().go(link, extra: message.data);
      }
    }
  }

  /// Initialize the remote config service of firebase to use remote based configuration of the app.
  static Future<void> initializeRemoteConfig() async {
    //First activate, then fetch the remote configuration to avoid loading times for users
    final remoteConfig = FirebaseRemoteConfig.instance;

    if (remoteConfig.lastFetchStatus == RemoteConfigFetchStatus.noFetchYet) {
      //Set defaults that aren't fetched yet
      remoteConfig.setDefaults(const {
        "enable_firebase": false,
        "app_store_url": "",
        "play_store_url": "",
        "support_email": "engelsburg.planer@gmail.com",
      });
    }

    //Activate the config
    await remoteConfig.activate();

    //Set remote config fetch settings and perform fetch
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    int backOff = 0;
    Future.doWhile(() async {
      try {
        await remoteConfig.fetchAndActivate();

        return true;
      } catch (_) {
        await Future.delayed(Duration(seconds: pow(2, backOff++).toInt()));

        return false;
      }
    });
  }
}
