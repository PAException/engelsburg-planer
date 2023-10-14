/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:flutter/material.dart';

typedef Json = Map<String, dynamic>;

typedef Listener<T> = FutureOr<void> Function(T t);
typedef Wrap<T> = T Function();
typedef Parser<T> = T Function(dynamic json);
typedef PropertySupplier<S, T> = S Function(T);

///
/// Builder
///

/// Widget Builder
typedef DataBuilder<T> = Widget Function(T t, RefreshCallback refresh, BuildContext context);
typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ErrorBuilder = Widget Function(ApiError error, BuildContext context);
typedef WrapBuilder<T> = Widget Function(T t, BuildContext context);
