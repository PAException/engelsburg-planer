/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/backend/database/state/theme_state.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:engelsburg_planer/src/view/routing/route_generator.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

/// The app itself
class EngelsburgPlaner extends StatelessWidget {
  const EngelsburgPlaner({super.key});

  @override
  Widget build(BuildContext context) {
    //Start app
    Analytics.logAppOpen();
    GlobalContext.firstContext = context;
    InitializingPriority.context.initialize();

    return Consumer2<ThemeState, AppConfigState>(
      builder: (context, theme, config, _) {
        var router = AppRouter.router(context);

        Crashlytics.log("Start building app..");
        return MaterialApp.router(
          builder: NoOverScrollEffect.get,
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.appTitle,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme.lightTheme(),
          darkTheme: theme.darkTheme(),
          themeMode: theme.mode,
          routerConfig: router,
        );
      },
    );
  }
}
