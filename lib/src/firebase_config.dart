/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/firebase_options.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/db/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Util class for all firebase initializations and configurations.
class FirebaseConfig {
  /// Initializes every used firebase service
  static Future<void> initialize() async {
    //Init the core firebaseApp
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    //Init sub services
    initializeFirebaseMessaging();
    initializeDynamicLinks();
    if (!kDebugMode) initializeCrashlytics();
    initializeRemoteConfig();
  }

  /// Initialize FCM - initialNotification, tokenRefresh action
  static void initializeFirebaseMessaging() async {
    //Check if app was opened via a notification
    FirebaseMessaging.instance.getInitialMessage().then(handleOpenedRemoteMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(handleOpenedRemoteMessage);

    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, // Required to display a heads up notification
      badge: true,
      sound: true,
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();
    localNotifications.initialize(
      const InitializationSettings(android: AndroidInitializationSettings("mipmap/ic_launcher")),
      onDidReceiveNotificationResponse: handleLocalOpenedNotification,
      onDidReceiveBackgroundNotificationResponse: handleLocalOpenedNotification,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        //TODO
      }

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
      updateNotificationSettings(
        token,
        await (await SubstituteSettings.get().load()).priorityTopics(),
      ).build().api(ignore);
    });
  }

  static void handleLocalOpenedNotification(NotificationResponse details) =>
      handleOpenedRemoteMessage(RemoteMessage(data: {"link": details.payload}));

  static void handleOpenedRemoteMessage(RemoteMessage? message) {
    if (message == null) return;
    if (message.data.isNotEmpty) {
      String? link = message.data["link"];
      if (link != null && link.isNotEmpty) globalContext().go(link, extra: message.data);
    }
  }

  /// Initialize the dynamic link firebase service to accept to app linking.
  static void initializeDynamicLinks() async {
    //Register listener on any links that are opened in the app.
    FirebaseDynamicLinks.instance.onLink.listen((linkData) async {
      //Wait for app to be initialized
      await Future.doWhile(() => GlobalContext.key.currentContext == null);

      //Push screen after WidgetTree is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalContext().go(linkData.link.toString());
      });
    });

    //Get initial dynamic links on app start (installed or terminated)
    return FirebaseDynamicLinks.instance.getInitialLink().then((value) {
      if (value == null) return;

      //Push screen after WidgetTree is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        globalContext().go(value.link.toString());
      });
    });
  }

  /// Initialize the crashlytics firebase service to catch and report all errors.
  static void initializeCrashlytics() {
    //Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    //Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  /// Initialize the remote config service of firebase to use remote based configuration of the app.
  static void initializeRemoteConfig() {
    //First activate, then fetch the remote configuration to avoid loading times for users
    final remoteConfig = FirebaseRemoteConfig.instance;

    //Set defaults that aren't fetched yet
    remoteConfig.setDefaults(const {
      "enable_firebase": false,
      "app_store_url": "",
      "play_store_url": "",
      "support_email": "huerkamp.paul@gmail.com",
    });

    //Activate the config
    remoteConfig.activate();

    //Set remote config fetch settings and perform fetch
    remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    remoteConfig.fetchAndActivate();
  }
}
