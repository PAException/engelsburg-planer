/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/app.dart';
import 'package:engelsburg_planer/src/backend/db/db_service.dart';
import 'package:engelsburg_planer/src/firebase_config.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/state/network_state.dart';
import 'package:engelsburg_planer/src/models/state/semester_state.dart';
import 'package:engelsburg_planer/src/models/state/substitute_state.dart';
import 'package:engelsburg_planer/src/models/state/theme_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/isolated_worker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Initialize and run app
void main() async {
  await initialize();

  runApp(wrapProvider(const EngelsburgPlaner()));
}

/// Wrap provider in app
Widget wrapProvider(Widget app) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeState()),
      ChangeNotifierProvider(create: (_) => UserState()),
      ChangeNotifierProvider(create: (_) => SubstituteSettingsState()),
      //ChangeNotifierProvider(create: (_) => NotificationSettings()),
      ChangeNotifierProvider(create: (_) => NetworkState()),
      ChangeNotifierProvider(create: (_) => SemesterState()),
      ChangeNotifierProvider(create: (_) => AppConfigurationState()),
    ],
    child: app,
  );
}

/// Initialize various services/instances
Future<void> initialize() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    FirebaseConfig.initialize(),
    CacheService.initialize(),
    DatabaseService.initialize(),
    IsolatedWorker.initialize(),
    Firebase.initializeApp(),
  ]);
  //if (kDebugMode) await FirebaseAuth.instance.useAuthEmulator('10.0.0.2', 9099);
}

/// Initialize various services/instances which need a context
Future<void> initializeWithContext(BuildContext context) async {
  DataService.initialize(context);
}
