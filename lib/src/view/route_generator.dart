/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/home/home_page.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:go_router/go_router.dart';

class Router {
  static late ValueKey<String> currentHomePageKey;

  static GoRouter router(BuildContext context, AppConfigurationState config) {
    Iterable<String> routes = Pages.navBar.map((e) => e.path.substring(1));
    Iterable<GoRoute> allRoutes = Pages.all
      ..removeWhere((e) => routes.contains(e.path.substring(1)));

    return GoRouter(
      navigatorKey: GlobalContext.key,
      debugLogDiagnostics: kDebugMode,
      initialLocation: "/",
      routes: [
        GoRoute(
          path: "/:page(|${routes.join("|")})",
          builder: (context, state) {
            currentHomePageKey = state.pageKey;

            return HomePage(
              key: state.pageKey,
              state: state,
            );
          },
        ),
        ...allRoutes,
      ],
    );
  }
}
