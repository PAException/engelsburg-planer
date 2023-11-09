/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/material.dart';

BuildContext globalContext() => GlobalContext.key.currentContext ?? GlobalContext.firstContext!;

class GlobalContext {
  static final key = GlobalKey<NavigatorState>();
  static BuildContext? firstContext;
}
