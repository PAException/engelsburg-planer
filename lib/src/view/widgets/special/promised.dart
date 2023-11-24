/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/services/promise.dart';
import 'package:flutter/material.dart';

const Widget kLoadingWidget = Center(child: CircularProgressIndicator());

typedef DataBuilder<T> = Widget Function(T t, RefreshCallback refresh, BuildContext context);
typedef LoadingBuilder = Widget Function(BuildContext context);
typedef ErrorBuilder = Widget Function(ApiError error, BuildContext context);

/// Widget to wrap a [Promise]
///
/// Difference in behaviour to plain Promise:
/// - data widget gets only build if data is available (not if fetch doesn't return any data)
/// - error widget also gets only build if an api error is present
/// - if none of the listed above is the case return the loading widget
///
/// This widget also dispatches [NetworkStateNotification]'s.
///
/// If no loading widget builder is defined
/// use per default a centered default [CircularProgressIndicator]
class Promised<T> extends StatefulWidget {
  final Promise<T> promise;
  final DataBuilder<List<T>> dataBuilder;
  final ErrorBuilder errorBuilder;
  final LoadingBuilder? loadingBuilder;

  const Promised({
    super.key,
    required this.promise,
    required this.dataBuilder,
    required this.errorBuilder,
    this.loadingBuilder,
  });

  @override
  State<Promised<T>> createState() => _PromisedState<T>();
}

class _PromisedState<T> extends State<Promised<T>> {
  Future? current;

  void load() => current = widget.promise.load();

  Future<void> _refresh() async {
    load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) load();

    return FutureBuilder(
      future: current,
      builder: (context, snapshot) {
        //If future completed
        if (snapshot.connectionState == ConnectionState.done) {
          var data = widget.promise.data;
          var error = widget.promise.currentError;

          //If data build data widget, if error present build error widget
          if (data.isNotEmpty) {
            return widget.dataBuilder.call(
              data,
              _refresh,
              context,
            );
          }
          if (error != null) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(child: widget.errorBuilder(error, context)),
            );
          }

          //If none present build loading widget
        }

        //Otherwise build loading widget
        return widget.loadingBuilder?.call(context) ?? kLoadingWidget;
      },
    );
  }
}
