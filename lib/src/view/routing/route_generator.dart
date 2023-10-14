/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/firebase/analytics.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/home_page.dart';
import 'package:engelsburg_planer/src/view/routing/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static late ValueKey<String> currentHomePageKey;

  static GoRouter router(BuildContext context) {
    Iterable<String> routes = Pages.navBar.map((e) => e.path.substring(1));
    Iterable<GoRoute> allRoutes = Pages.all
      ..removeWhere((e) => routes.contains(e.path.substring(1)));

    return GoRouter(
      navigatorKey: GlobalContext.key,
      debugLogDiagnostics: kDebugMode,
      initialLocation: "/",
      redirect: (context, state) {
        //Set current screen for analytics
        Analytics.interaction.screen(state.uri.toString());

        if (context.read<AppConfigState>().isConfigured) return null;

        return "/introduction";
      },
      routes: [
        GoRoute(
          path: "/:page(|${routes.join("|")})",
          pageBuilder: (context, state) {
            currentHomePageKey = state.pageKey;

            return NoTransitionPage(
              child: HomePage(
                key: state.pageKey,
                state: state,
              ),
            );
          },
        ),
        ...allRoutes,
      ],
    );
  }
}
