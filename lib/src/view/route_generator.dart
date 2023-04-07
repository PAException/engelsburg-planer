/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/home/home_page.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class Router {
  static late ValueKey<String> currentHomePageKey;

  static GoRouter router(BuildContext context, AppConfigState config) {
    Iterable<String> routes = Pages.navBar.map((e) => e.path.substring(1));
    Iterable<GoRoute> allRoutes = Pages.all
      ..removeWhere((e) => routes.contains(e.path.substring(1)));

    return GoRouter(
      navigatorKey: GlobalContext.key,
      debugLogDiagnostics: kDebugMode,
      initialLocation: "/",
      redirect: (context, state) {
        if (context.read<AppConfigState>().isConfigured) return null;

        return "/introduction";
      },
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
      observers: [
        NavigatorObserver(),
      ],
    );
  }
}

class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    FirebaseAnalytics.instance.setCurrentScreen(screenName: route.settings.name);
  }
}
