/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/article.dart';
import 'package:engelsburg_planer/src/view/pages/introduction.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_page.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_extended.dart';
import 'package:engelsburg_planer/src/view/pages/article/article_saved_page.dart';
import 'package:engelsburg_planer/src/view/pages/grade/grade_page.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_page.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_page.dart';
import 'package:engelsburg_planer/src/view/pages/timetable/timetable_page.dart';
import 'package:engelsburg_planer/src/view/pages/auth/account/account_security_page.dart';
import 'package:engelsburg_planer/src/view/pages/auth/account/account_advanced_page.dart';
import 'package:engelsburg_planer/src/view/pages/auth/account_page.dart';
import 'package:engelsburg_planer/src/view/pages/auth/auth_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/settings_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/settings_notifications_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/settings_subject_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/settings_substitute_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/settings_theme_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/about_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/cafeteria_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/events_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/solar_panel_page.dart';
import 'package:engelsburg_planer/src/view/widgets/special/network_status.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef L10n = String Function(AppLocalizations l10n);

class NamedRoute extends GoRoute {
  final String? absolutePath;

  NamedRoute({
    required super.path,
    this.absolutePath,
    super.builder,
    super.pageBuilder,
    super.parentNavigatorKey,
    super.routes,
    super.redirect,
    String? name,
  }) : super(name: name ?? path);

  NamedRoute.static({
    required super.path,
    this.absolutePath,
    required Widget page,
    super.parentNavigatorKey,
    super.routes,
    super.redirect,
    String? name,
  }) : super(name: name ?? path, builder: (context, state) => page);
}

class StyledRoute extends NamedRoute {
  late final GoRouterWidgetBuilder? widgetBuilder;
  final IconData icon;
  final L10n label;
  final List<Widget> actions;
  final AppBar Function(BuildContext context)? appBar;

  StyledRoute.static({
    required super.path,
    super.absolutePath,
    required Widget page,
    super.name,
    super.parentNavigatorKey,
    super.routes,
    super.redirect,
    required this.icon,
    required this.label,
    this.actions = const [],
    this.appBar,
  }) : super(
          builder: (context, state) => buildPage(null, label, (_, __) => page, context, state),
        ) {
    widgetBuilder = (_, __) => page;
  }

  StyledRoute({
    required super.path,
    super.absolutePath,
    this.widgetBuilder,
    super.pageBuilder,
    super.name,
    super.parentNavigatorKey,
    super.routes,
    super.redirect,
    required this.icon,
    required this.label,
    this.actions = const [],
    this.appBar,
  }) : super(
            builder: widgetBuilder == null
                ? null
                : (context, state) =>
                    buildPage(null, label, (_, __) => widgetBuilder.call(_, __), context, state));

  static Widget buildPage(
    AppBar Function(BuildContext context)? appBar,
    L10n label,
    GoRouterWidgetBuilder builder,
    BuildContext context,
    GoRouterState state, {
    bool standalone = true,
  }) {
    if (!standalone) return builder.call(context, state);

    return Scaffold(
      appBar: appBar?.call(context) ??
          AppBar(
            title: Text(label.call(context.l10n)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
              onPressed: () {
                var route = GoRouterState.of(context).fullPath!;
                String goTo = route.substring(0, route.lastIndexOf("/"));

                context.navigate(goTo == "" ? "/" : goTo);
              },
            ),
          ),
      body: NetworkStatusBar(
        child: builder.call(context, state),
      ),
    );
  }

  Widget build(BuildContext context, GoRouterState state, {bool standalone = true}) =>
      buildPage(appBar, label, widgetBuilder!, context, state, standalone: standalone);

  String getLabel(AppLocalizations l10n) => label.call(l10n);

  BottomNavigationBarItem toBottomNavigationBarItem(BuildContext context) =>
      BottomNavigationBarItem(
        icon: Icon(icon),
        label: getLabel(context.l10n),
      );

  ListTile toDrawerListTile(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(getLabel(context.l10n)),
        onTap: () {
          if (Scaffold.of(context).isDrawerOpen) context.pop();
          context.navigate(super.absolutePath ?? super.path);
        },
      );

  NavigationRailDestination toNavigationRailDestination(BuildContext context) =>
      NavigationRailDestination(
        icon: Icon(icon),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        label: Text(getLabel(context.l10n)),
      );
}

class Pages {
  /// State managed appType [AppConfigState]
  static UserType userType = UserType.other;

  /// Count of pages that will be located in the navigation bar
  static const int navigationBarCount = 5;

  static List<GoRoute> get all => [
        introduction,
        account,
        articles,
        savedArticles,
        extendedArticle,
        substitutes,
        timetable,
        grades,
        tasks,
        cafeteria,
        events,
        solarPanel,
        settings,
        about,
        if (FirebaseRemoteConfig.instance.getBool("enable_firebase")) signIn,
      ];

  /// Pages that are located in the bottom navigation bar or the drawer
  /// !!! Pages need to be routed !!!
  static List<StyledRoute> get relevant => [
        articles,
        substitutes,
        if (userType != UserType.other) timetable,
        if (userType != UserType.other) grades,
        if (userType != UserType.other) tasks,
        cafeteria,
        events,
        solarPanel,
        settings,
        about,
      ].toList();

  /// Returns all pages for the navigation bar
  static Iterable<StyledRoute> get navBar => relevant.take(navigationBarCount);

  /// Returns all pages for the drawer
  static Iterable<StyledRoute> get drawer => relevant.skip(navigationBarCount);

  static List<BottomNavigationBarItem> navBarItems(BuildContext context) =>
      navBar.map((e) => e.toBottomNavigationBarItem(context)).toList();

  static List<NavigationRailDestination> navRailItems(BuildContext context) =>
      navBar.map((e) => e.toNavigationRailDestination(context)).toList();

  static List<NavigationRailDestination> extendedNavRailItems(BuildContext context) =>
      drawer.map((e) => e.toNavigationRailDestination(context)).toList();

  static List<ListTile> drawerTiles(BuildContext context) =>
      drawer.map((e) => e.toDrawerListTile(context)).toList();

  static final GoRoute introduction = NamedRoute.static(
    path: "/introduction",
    page: const IntroductionPage(),
  );

  static final StyledRoute account = StyledRoute.static(
    page: const AccountPage(),
    path: "/account",
    label: (l10n) => "Account",
    icon: Icons.account_circle_outlined,
    routes: [
      GoRoute(
        path: "security",
        builder: (context, state) => const AccountSecurityPage(),
      ),
      GoRoute(
        path: "advanced",
        builder: (context, state) => const AccountAdvancedPage(),
      ),
    ],
  );

  static final StyledRoute articles = StyledRoute.static(
    page: const ArticlePage(),
    path: "/article",
    label: (l10n) => l10n.articles,
    icon: Icons.library_books,
  );

  static final GoRoute extendedArticle = NamedRoute(
    path: "/article/:articleId",
    builder: (context, state) => ExtendedArticle(
      articleId: state.pathParameters["articleId"] == null ? null : int.parse(state.pathParameters["articleId"]!),
      hero: state.uri.queryParameters["hero"],
      article: state.extra as Article?,
    ),
  );

  static final StyledRoute savedArticles = StyledRoute.static(
    page: const SavedArticlePage(),
    path: "/article/saved",
    label: (l10n) => l10n.savedArticles,
    icon: Icons.bookmarks_outlined,
  );

  static final StyledRoute substitutes = StyledRoute.static(
    page: const SubstitutesPage(),
    path: "/substitutes",
    label: (l10n) => l10n.substitutes,
    icon: Icons.dashboard,
    actions: [
      Builder(builder: (context) {
        return IconButton(
          onPressed: () => context.push("/settings/substitute?callbackUrl=/substitutes"),
          icon: const Icon(Icons.settings),
        );
      }),
    ],
  );

  static final StyledRoute timetable = StyledRoute.static(
    page: const TimetablePage(),
    path: "/timetable",
    label: (l10n) => l10n.timetable,
    icon: Icons.apps_outlined,
  );

  static final StyledRoute grades = StyledRoute.static(
    page: const GradePage(),
    path: "/grades",
    label: (l10n) => l10n.grades,
    icon: Icons.bar_chart,
    actions: [
      Builder(builder: (context) {
        return IconButton(
          onPressed: () => context.push("/settings/subject?callbackUrl=/grades"),
          icon: const Icon(Icons.settings),
        );
      }),
    ],
  );

  static final StyledRoute tasks = StyledRoute.static(
    page: const TaskPage(),
    path: "/tasks",
    label: (l10n) => l10n.tasks,
    icon: Icons.assignment,
  );

  static final StyledRoute cafeteria = StyledRoute.static(
    page: const CafeteriaPage(),
    path: "/cafeteria",
    label: (l10n) => l10n.cafeteria,
    icon: Icons.restaurant_menu,
  );

  static final StyledRoute events = StyledRoute.static(
    page: const EventsPage(),
    path: "/events",
    label: (l10n) => l10n.events,
    icon: Icons.watch_later,
  );

  static final StyledRoute solarPanel = StyledRoute.static(
    page: const SolarPanelPage(),
    path: "/solarPanel",
    label: (l10n) => l10n.solarPanelData,
    icon: Icons.wb_sunny,
  );

  static final StyledRoute settings = StyledRoute.static(
    page: const SettingsPage(),
    path: "/settings",
    label: (l10n) => l10n.settings,
    icon: Icons.settings,
    routes: [
      themeSettings,
      substituteSettings,
      notificationSettings,
      subjectSettings,
    ],
  );

  static final StyledRoute themeSettings = StyledRoute.static(
    page: const ThemeSettingsPage(),
    path: "theme",
    absolutePath: "/settings/theme",
    label: (l10n) => l10n.themeSettings,
    icon: Icons.brush_outlined,
  );

  static final StyledRoute substituteSettings = StyledRoute.static(
    page: const SubstituteSettingsPage(),
    path: "substitute",
    absolutePath: "/settings/substitute",
    label: (l10n) => l10n.substitutes,
    icon: Icons.dashboard,
  );

  static final StyledRoute notificationSettings = StyledRoute.static(
    page: const NotificationSettingsPage(),
    path: "notification",
    absolutePath: "/settings/notification",
    icon: Icons.notifications_outlined,
    label: (l10n) => l10n.notificationSettings,
  );

  static final StyledRoute subjectSettings = StyledRoute.static(
    page: const SubjectSettingsPage(),
    path: "subject",
    absolutePath: "/settings/subject",
    label: (l10n) => l10n.subjects,
    icon: Icons.school,
  );

  static final StyledRoute about = StyledRoute.static(
    page: const AboutPage(),
    path: "/about",
    label: (l10n) => l10n.about,
    icon: Icons.info,
  );

  static final StyledRoute signIn = StyledRoute.static(
    page: const SignInPage(),
    path: "/signIn",
    label: (l10n) => l10n.signIn,
    icon: Icons.login,
  );
}
