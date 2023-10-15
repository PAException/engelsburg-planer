/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/app.dart';
import 'package:engelsburg_planer/src/backend/db/db_service.dart';
import 'package:engelsburg_planer/src/models/db/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/firebase/firebase_config.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/state/network_state.dart';
import 'package:engelsburg_planer/src/models/state/semester_state.dart';
import 'package:engelsburg_planer/src/models/state/theme_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/isolated_worker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

/// Initialize and run app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InitializingPriority.instant.initialize();

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
  CacheService.initialize: InitializingPriority.instant,
  DatabaseService.initialize: InitializingPriority.instant,
  IsolatedWorker.initialize: InitializingPriority.instant,
  Hive.initFlutter: InitializingPriority.instant,
  DataService.initialize: InitializingPriority.needsContext,
  FirebaseConfig.initializeFCM: InitializingPriority.afterAppConfig,
  NotificationHelper.init: InitializingPriority.afterAppConfig,
};

/// Initialize various services/instances which need a context
Future<void> initializeWithContext(BuildContext context) async {
  DataService.initialize();
}


enum InitializingPriority {
  instant,
  needsContext,
  afterAppConfig,
}

extension InitializingPriorityUtils on InitializingPriority{
  Future initialize() {
    return toInitialize.entries.where((entry) => entry.value == this).asyncMap(
          (entry) async => await Future.value(entry.key.call()),
    );
  }
}
