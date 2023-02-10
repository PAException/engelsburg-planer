/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/home/article/extended_article.dart';
import 'package:engelsburg_planer/src/view/pages/home/article/saved_articles_page.dart';
import 'package:engelsburg_planer/src/view/pages/home/articles_page.dart';
import 'package:engelsburg_planer/src/view/pages/home/grades_page.dart';
import 'package:engelsburg_planer/src/view/pages/home/substitutes_page.dart';
import 'package:engelsburg_planer/src/view/pages/home/tasks_page.dart';
import 'package:engelsburg_planer/src/view/pages/home/timetable_page.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/account_page.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/auth_page.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/settings_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject_settings_page.dart';
import 'package:engelsburg_planer/src/view/pages/settings/theme_settings_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/about_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/about_school_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/cafeteria_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/events_page.dart';
import 'package:engelsburg_planer/src/view/pages/util/solar_panel_page.dart';
import 'package:engelsburg_planer/src/view/widgets/locked.dart';
import 'package:engelsburg_planer/src/view/widgets/network_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../../models/api/article.dart';

typedef L10n = String Function(AppLocalizations l10n);

extension GoRouteExtension on GoRoute {
  GoRoute removeBuilders() {
    return GoRoute(
      path: path,
      name: name,
      redirect: (context, state) => path,
      parentNavigatorKey: parentNavigatorKey,
      routes: routes,
    );
  }
}

class StyledRoute extends GoRoute {
  late final GoRouterWidgetBuilder? widgetBuilder;
  final IconData icon;
  final L10n label;
  final List<Widget> actions;
  final AppBar Function(BuildContext context)? appBar;

  StyledRoute.static({
    required super.path,
    required Widget page,
    super.name,
    super.parentNavigatorKey,
    super.routes,
    super.redirect,
    required this.icon,
    required this.label,
    this.actions = const [],
    this.appBar,
  }) : super(builder: (context, state) => buildPage(null, label, (_, __) => page, context, state)) {
    widgetBuilder = (_, __) => page;
  }

  StyledRoute({
    required super.path,
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
              icon: const Icon(Icons.arrow_back_outlined),
              onPressed: () {
                var route = ModalRoute.of(context)!.settings.name!;
                var goTo = route.substring(0, route.lastIndexOf("/"));

                context.go(goTo == "" ? "/" : goTo);
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
        onTap: () => context.go(super.path),
      );
}

class Pages {
  /// State managed appType [AppConfigurationState]
  static AppType appType = AppType.other;

  /// Count of pages that will be located in the navigation bar
  static const int navigationBarCount = 5;

  static List<GoRoute> get all => [
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
        substituteSettings,
        themeSettings,
        subjectSettings,
        about,
        aboutSchool,
        signUp,
        signIn,
      ];

  /// Pages that are located in the bottom navigation bar or the drawer
  /// !!! Pages need to be routed !!!
  static List<StyledRoute> get relevant => [
        articles,
        substitutes,
        if (appType != AppType.other) timetable,
        if (appType != AppType.other) grades,
        if (appType != AppType.other) tasks,
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

  static List<ListTile> drawerTiles(BuildContext context) =>
      drawer.map((e) => e.toDrawerListTile(context)).toList();

  static final StyledRoute account = StyledRoute.static(
    page: const AccountPage(),
    path: "/account",
    label: (l10n) => "Account",
    icon: Icons.account_circle_outlined,
  );

  static final StyledRoute articles = StyledRoute.static(
    page: const ArticlesPage(),
    path: "/article",
    label: (l10n) => l10n.articles,
    icon: Icons.library_books,
  );

  static final GoRoute extendedArticle = GoRoute(
    path: "/article/:articleId",
    builder: (context, state) => ExtendedArticle(
      articleId: state.params["articleId"] == null ? null : int.parse(state.params["articleId"]!),
      hero: state.queryParams["hero"],
      article: state.extra as Article?,
    ),
  );

  static final StyledRoute savedArticles = StyledRoute.static(
    page: const SavedArticlesPage(),
    path: "/article/saved",
    label: (l10n) => l10n.savedArticles,
    icon: Icons.bookmark_outlined,
  );

  static final StyledRoute substitutes = StyledRoute.static(
    page: const SubstitutesPage(),
    path: "/substitutes",
    label: (l10n) => l10n.substitutes,
    icon: Icons.dashboard,
    actions: [
      Builder(builder: (context) {
        return Locked(
          enforceVerified: false,
          child: IconButton(
            onPressed: () => context.go(substituteSettings.path),
            icon: const Icon(Icons.settings),
          ),
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
    page: const GradesPage(),
    path: "/grades",
    label: (l10n) => l10n.grades,
    icon: Icons.assessment,
  );

  static final StyledRoute tasks = StyledRoute.static(
    page: const TasksPage(),
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
  );

  static final StyledRoute themeSettings = StyledRoute.static(
    page: const ThemeSettingsPage(),
    path: "/settings/theme",
    label: (l10n) => l10n.themeSettings,
    icon: Icons.brush_outlined,
  );

  static final StyledRoute substituteSettings = StyledRoute.static(
    page: const SubstitutesPage(), //TODO!!!!!!!
    path: "/settings/substitute",
    label: (l10n) => l10n.substitutes,
    icon: Icons.dashboard,
  );

  static final StyledRoute subjectSettings = StyledRoute.static(
    page: const SubjectSettingsPage(),
    path: "/settings/subject",
    label: (l10n) => l10n.subjects,
    icon: Icons.school,
  );

  static final StyledRoute about = StyledRoute.static(
    page: const AboutPage(),
    path: "/about",
    label: (l10n) => l10n.about,
    icon: Icons.info,
  );

  static final StyledRoute aboutSchool = StyledRoute.static(
    page: const AboutSchoolPage(),
    path: "/about/school",
    label: (l10n) => l10n.aboutTheSchool,
    icon: Icons.info,
  );

  static final StyledRoute signUp = StyledRoute.static(
    page: const AuthenticationPage.signUp(),
    path: "/signUp",
    label: (l10n) => l10n.signUp,
    icon: Icons.login,
  );

  static final StyledRoute signIn = StyledRoute.static(
    page: const AuthenticationPage.signIn(),
    path: "/signIn",
    label: (l10n) => l10n.signIn,
    icon: Icons.login,
  );
}
