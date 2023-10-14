/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class RouteModifier extends StatefulWidget {
  const RouteModifier({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<RouteModifier> createState() => _RouteModifierState();
}

class _RouteModifierState extends State<RouteModifier> {
  String? callbackUrl;
  late GoRouter router;
  late RouteInformationProvider routeInformation;

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    router = GoRouter.of(context);
    routeInformation = GoRouter.of(context).routeInformationProvider;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      router.routerDelegate.removeListener(routerListener);
      router.routerDelegate.addListener(routerListener);
    });
  }

  @override
  void dispose() {
    super.dispose();
    router.routerDelegate.removeListener(routerListener);
  }

  void routerListener() {
    if (callbackUrl != null) {
      router.go(callbackUrl!);
      callbackUrl = null;
    } else {
      //Get params from url string as map
      Map<String, String> params = routeInformation.value.uri
              .toString()
              .split("?")
              .nullableAt(1)
              ?.split("&")
              .asMap()
              .map((_, param) {
            var keyAndValue = param.split("=");
            return MapEntry(keyAndValue[0], keyAndValue[1]);
          }) ??
          {};

      //Actions for each param
      params.forEach((key, value) {
        switch (key) {
          case "callbackUrl":
            callbackUrl = value;
            break;
        }
      });
    }
  }
}
