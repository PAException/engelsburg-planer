/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/app.dart';
import 'package:engelsburg_planer/src/backend/database/cache/app_persistent_data.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/sql/sql_database.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/backend/database/state/network_state.dart';
import 'package:engelsburg_planer/src/backend/database/state/semester_state.dart';
import 'package:engelsburg_planer/src/backend/database/state/theme_state.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/services/firebase/firebase_config.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/isolated_worker.dart';
import 'package:engelsburg_planer/src/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

/// Initialize and run app
void main() async {
  Logger.rootLevel = Level.fine;

  Logger.forType<EngelsburgPlaner>().info("Starting app...");
  WidgetsFlutterBinding.ensureInitialized();

  await InitializingPriority.instant.initialize();
  await InitializingPriority.afterInstant.initialize();

  runApp(wrapProvider(const EngelsburgPlaner()));
}

/// Wrap provider in app
Widget wrapProvider(Widget app) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeState()),
      ChangeNotifierProvider(create: (_) => UserState()),
      ChangeNotifierProvider(create: (_) => NetworkState()),
      ChangeNotifierProvider(create: (_) => SemesterState()),
      ChangeNotifierProvider(create: (_) => AppConfigState()),
    ],
    child: app,
  );
}

Map<FutureOr<void> Function(), InitializingPriority> toInitialize = {
  FirebaseConfig.initialize: InitializingPriority.instant,
  SqlDatabase.initialize: InitializingPriority.instant,
  IsolatedWorker.initialize: InitializingPriority.instant,
  Hive.initFlutter: InitializingPriority.instant,
  AppPersistentData.initialize: InitializingPriority.afterInstant,
  DataService.initialize: InitializingPriority.context,
  NotificationHelper.init: InitializingPriority.afterAppConfig,
  FirebaseConfig.initializeFCM: InitializingPriority.afterAppConfig,
};

enum InitializingPriority {
  instant,
  afterInstant,
  context,
  afterContext,
  afterAppConfig,
}

extension InitializingPriorityUtils on InitializingPriority{
  Future initialize() {
    return toInitialize.entries.where((entry) => entry.value == this).asyncMap(
          (entry) async => await Future.value(entry.key.call()),
    ).then((value) {
      Logger.forType<EngelsburgPlaner>().info("Initialized '$name' priority");
    });
  }
}
