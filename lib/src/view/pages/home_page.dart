/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';
import 'dart:math';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:provider/provider.dart';
import 'package:engelsburg_planer/src/view/routing/page.dart';
import 'package:engelsburg_planer/src/view/pages/auth/auth_page.dart';
import 'package:engelsburg_planer/src/view/routing/route_modifier.dart';
import 'package:engelsburg_planer/src/view/widgets/app_icon.dart';
import 'package:engelsburg_planer/src/view/widgets/special/network_status.dart';
import 'package:engelsburg_planer/src/view/widgets/special/updatable.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:go_router/go_router.dart' hide GoRouterHelper;

/// Default page of the app.
/// Contains a PageView and a NavigationBar with 5 pages.
/// All pages can be pushed with arguments. While pushing the PageView will change to
/// that screen and send updated data through the args argument.
/// Pushes are managed by [RouteGenerator.generateRoute], arguments to the pages are passed via
/// streams, the page needs to inherit from [UpdatableWidget].
class HomePage extends StatefulWidget {
  final GoRouterState state;

  const HomePage({required this.state, super.key});

  @override
  HomePageState createState() => HomePageState();
}

Map<String, StreamController<Map<String, dynamic>>> _connections = {};

/// Create a stream-connection based on an identifier that will be triggered,
/// if that page is pushed with a query.
/// The identifier should be the path e.g. /article
Stream<Map<String, dynamic>> createConnection(String identifier) {
  var controller = StreamController<Map<String, dynamic>>();
  _connections[identifier] = controller;

  return controller.stream;
}

void sendUpdate(String identifier, Map<String, dynamic> data) {
  if (data.isEmpty) return;
  if (identifier == "/") identifier = "/article";

  _connections[identifier]?.add(data);
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Future? _animatingPage;
  bool extended = false;

  List<StyledRoute> pages = Pages.navBar.toList();

  /// Default animation to change the page.
  void page(int page) {
    //Update bottomNavigationBar
    setState(() => _currentPage = page);

    //Lock animation so page view will not attempt to navigate to page
    _animatingPage = _pageController
        .animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.decelerate,
    )
        .whenComplete(() {
      _animatingPage = null;
    });
  }

  /// Evaluate arguments
  void evaluateRouterState() {
    //Execute after building the tree
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      var path = widget.state.uri.toString();
      if (path == "") return;

      //Push (switch to) requested page
      page(max(0, pages.indexWhere((e) => e.path == path)));

      //Update page with given arguments
      sendUpdate(path, widget.state.uri.queryParameters);
    });
  }

  void updateIndex(int index) {
    //If the current icon is tapped don't switch and send update to screen
    setState(() => extended = false);
    if (index == _currentPage) {
      sendUpdate(widget.state.uri.toString(), {"resetView": true});

      return;
    }

    if (index > pages.length - 1) {
      context.navigate(Pages.drawer.toList()[index - pages.length].path);
    } else {
      context.navigate(pages[index].path);
    }
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    evaluateRouterState();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RouteModifier(
      child: Consumer<AppConfigState>(
        builder: (context, config, _) {
          Crashlytics.set("appConfiguration", config.config);
          List<Widget> builtPages = pages.map((page) {
            //Build the page and pass the stream as argument
            return page.build(context, widget.state, standalone: false);
          }).toList();

          final appBar = AppBar(
            title: Text(context.l10n.appTitle),
            actions: pages.elementAt(_currentPage).actions,
          );

          final content = NetworkStatusBar(
            child: PageView(
              allowImplicitScrolling: false,
              controller: _pageController,
              onPageChanged: (index) {
                if (_animatingPage != null) return;

                context.navigate(pages[index].path);
              },
              children: builtPages,
            ),
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              if (context.isLandscape && constraints.maxWidth > 600) {
                return Scaffold(
                  appBar: AppBar(
                    title: appBar.title,
                    actions: appBar.actions,
                    automaticallyImplyLeading: false,
                  ),
                  drawer: const HomePageDrawer(includeBottomNavItems: true),
                  body: Row(
                    children: [
                      StatefulBuilder(builder: (context, setState) {
                        return Align(
                          alignment: Alignment.topCenter,
                          child: SingleChildScrollView(
                            child: IntrinsicHeight(
                              child: NavigationRail(
                                labelType: extended
                                    ? NavigationRailLabelType.none
                                    : NavigationRailLabelType.selected,
                                destinations: Pages.navRailItems(context),
                                extended: extended,
                                onDestinationSelected: updateIndex,
                                selectedIndex: _currentPage,
                                trailing: IconButton(
                                  icon: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Icon(Icons.more_horiz),
                                  ),
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const VerticalDivider(),
                      Expanded(child: content),
                    ],
                  ),
                );
              }

              return Scaffold(
                drawer: const HomePageDrawer(),
                appBar: appBar,
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  currentIndex: _currentPage,
                  items: Pages.navBarItems(context),
                  onTap: updateIndex,
                ),
                body: content,
              );
            },
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Drawer that is displayed on the homepage.
/// Includes AppLogo, title, motivation to signIn/Up, profile and other pages.
/// Order and visibility are dependent on the auth state and the app configuration.
class HomePageDrawer extends StatelessWidget {
  const HomePageDrawer({super.key, this.includeBottomNavItems = false});

  final bool includeBottomNavItems;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AppConfigState>(
        builder: (context, config, _) => ListView(
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onDoubleTap: () {
                  if (!kDebugMode) return;

                  context.read<AppConfigState>().remove();
                },
                child: Row(
                  children: [
                    const AppIcon(),
                    Expanded(
                      child: Text(
                        context.l10n.appTitle,
                        textScaleFactor: 1.5,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (FirebaseRemoteConfig.instance.getBool("enable_firebase"))
              Consumer<UserState>(
                builder: (context, user, child) => user.loggedIn
                    ? Pages.account.toDrawerListTile(context)
                    : const AuthenticationTiles(),
              ),
            const Divider(height: 8, thickness: 0)
                .paddingSymmetric(horizontal: 4),
            if (includeBottomNavItems)
              ...Pages.navBar.map((e) => e.toDrawerListTile(context)),
            if (includeBottomNavItems)
              const Divider(height: 8, thickness: 0)
                  .paddingSymmetric(horizontal: 4),
            ...Pages.drawerTiles(context),
          ],
        ),
      ),
    );
  }
}

class AuthenticationTiles extends StatelessWidget {
  const AuthenticationTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.loginForAdvancedFeatures,
            textAlign: TextAlign.center,
          ),
          8.0.heightBox,
          ElevatedButton(
            onPressed: () {
              context.pop();
              context.pushPage(const SignInPage());
            },
            child: Text(context.l10n.signIn),
          ),
        ],
      ),
    );
  }
}
