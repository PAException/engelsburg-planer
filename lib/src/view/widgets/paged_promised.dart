/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ItemBuilder<T> = Widget Function(T t, BuildContext context);

const Widget kLoadingWidget = Center(child: CircularProgressIndicator());

/// Widget to wrap a [PagedPromise]
///
/// Difference in behaviour to plain Promise:
/// - items get only build if data is available (not if fetch doesn't return any data)
/// - error widget also gets only build if an api error is present
/// - if none of the listed above is the case return the loading widget
///
/// This widget also dispatches [NetworkStateNotification]'s.
///
/// If no loading widget builder is defined
/// use per default a centered default [CircularProgressIndicator]
class PagedPromised<T> extends StatefulWidget {
  final PagedPromise<T> promise;
  final ItemBuilder<T> itemBuilder;
  final ItemBuilder<T> separatorBuilder;
  final ErrorBuilder errorBuilder;
  final LoadingBuilder? loadingBuilder;
  final ScrollController? scrollController;

  const PagedPromised({
    Key? key,
    required this.promise,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.errorBuilder,
    this.scrollController,
    this.loadingBuilder,
  }) : super(key: key);

  @override
  State<PagedPromised<T>> createState() => PagedPromisedState<T>();
}

class PagedPromisedState<T> extends State<PagedPromised<T>> {
  Future? current;

  void load() => current = widget.promise.load();

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: current,
      builder: (context, snapshot) {
        //If future completed
        if (snapshot.connectionState != ConnectionState.waiting) {
          var data = widget.promise.data;
          var error = widget.promise.currentError;

          //If data build data widget, if error present build error widget
          if (data.isNotEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                load();
                setState(() {});
              },
              child: PagedPromisedContent<T>(
                promise: widget.promise,
                itemBuilder: widget.itemBuilder,
                separatorBuilder: widget.separatorBuilder,
                scrollController: widget.scrollController ?? ScrollController(),
              ),
            );
          }

          if (snapshot.hasError) {
            error = ApiError(-1, snapshot.error.toString());
            if (kDebugMode) print(snapshot.error!);
            if (kDebugMode) print(snapshot.stackTrace!);
          }
          if (error != null) {
            return RefreshIndicator(
              onRefresh: () async {
                load();
                setState(() {});
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: widget.errorBuilder(error, context),
              ),
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

class PagedPromisedContent<T> extends StatefulWidget {
  final PagedPromise<T> promise;
  final ItemBuilder<T> itemBuilder;
  final ItemBuilder<T> separatorBuilder;
  final ScrollController scrollController;

  const PagedPromisedContent({
    Key? key,
    required this.promise,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.scrollController,
  }) : super(key: key);

  @override
  State<PagedPromisedContent<T>> createState() => _PagedPromisedContentState<T>();
}

class _PagedPromisedContentState<T> extends State<PagedPromisedContent<T>> {
  static const int scrollOffset = 300;

  /// Indicates whether new items are loaded or not.
  /// Also used to prevent the bug that new items were loaded but not rendered yet and more
  /// gets loaded because overscroll offset is still to high.
  bool loading = true;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(overscrollListener);
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.promise.data;

    return ListView.separated(
      controller: widget.scrollController,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemBuilder: (context, index) {
        //If half of the new data is rendered set loading to false
        if (data.length - (widget.promise.pagingSize ~/ 2) == index) loading = false;

        return widget.itemBuilder.call(data[index], context);
      },
      separatorBuilder: (context, index) => widget.separatorBuilder.call(data[index], context),
      itemCount: data.length,
    );
  }

  /// Does nothing if already loading, loads more if not and scrollController hits offset limit.
  void overscrollListener() async {
    if (loading) return;

    if (widget.scrollController.position.extentAfter <= scrollOffset) {
      loading = true;

      //After next() call data gets appended
      await widget.promise.next();
      setState(() {});
    }
  }
}
