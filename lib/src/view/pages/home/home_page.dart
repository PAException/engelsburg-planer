/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';
import 'dart:math';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';
import 'package:engelsburg_planer/src/view/widgets/network_status.dart';
import 'package:engelsburg_planer/src/view/widgets/util/updatable.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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

  _connections[identifier]?.add(data);
}

class HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late final PageController _pageController;
  int _currentPage = 0;
  Future? _animatingPage;

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
      var path = widget.state.location;
      if (path == "") return;

      //Push (switch to) requested page
      page(max(0, pages.indexWhere((e) => e.path == path)));

      //Update page with given arguments
      sendUpdate(path, widget.state.queryParams);
    });
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

    return Consumer<AppConfigurationState>(
      builder: (context, config, _) {
        List<Widget> builtPages = pages.map((page) {
          //Build the page and pass the stream as argument
          return page.build(context, widget.state, standalone: false);
        }).toList();

        return Scaffold(
          drawer: const HomePageDrawer(),
          appBar: AppBar(
            title: Text(context.l10n.appTitle),
            actions: pages.elementAt(_currentPage).actions,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: false,
            currentIndex: _currentPage,
            items: Pages.navBarItems(context),
            onTap: (index) {
              //If the current icon is tapped don't switch and send update to screen
              if (index == _currentPage) {
                sendUpdate(widget.state.location, {"resetView": true});

                return;
              }

              context.go(pages[index].path);
            },
          ),
          body: NetworkStatusBar(
            child: PageView(
              allowImplicitScrolling: false,
              controller: _pageController,
              onPageChanged: (index) {
                if (_animatingPage != null) return;

                context.go(pages[index].path);
              },
              children: builtPages,
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Drawer that is displayed on the homepage.
/// Includes AppLogo, title, motivation to signIn/Up, profile and other pages.
/// Order and visibility are dependent on the auth state and the app configuration.
class HomePageDrawer extends StatelessWidget {
  const HomePageDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AppConfigurationState>(
        builder: (context, config, _) => ListView(
          children: [
            Container(
              height: 100,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Image.asset(AssetPaths.appLogo),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.appTitle,
                      textScaleFactor: 1.5,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            Consumer<UserState>(
              builder: (context, user, child) => user.loggedIn
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Pages.account.toDrawerListTile(context),
                    )
                  : const AuthenticationTiles(),
            ),
            ...Pages.drawerTiles(context),
          ],
        ),
      ),
    );
  }
}

class AuthenticationTiles extends StatelessWidget {
  const AuthenticationTiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context)!.loginForAdvancedFeatures,
            textAlign: TextAlign.center,
          ),
          8.0.heightBox,
          ElevatedButton(
            onPressed: () {
              context.go("/signUp");
            },
            child: Text(AppLocalizations.of(context)!.signUp),
          ),
          8.0.heightBox,
          ElevatedButton(
            onPressed: () {
              context.go("/signIn");
            },
            child: Text(AppLocalizations.of(context)!.signIn),
          ),
        ],
      ),
    );
  }
}
