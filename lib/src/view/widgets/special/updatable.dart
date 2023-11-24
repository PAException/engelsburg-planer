/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:flutter/cupertino.dart';

abstract class UpdatableWidget<T> extends StatefulWidget {
  Stream<T> get update;

  const UpdatableWidget({super.key});
}

abstract class UpdatableState<T, S extends UpdatableWidget<T>> extends State<S> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.update.listen(onUpdate);
    });
  }

  void onUpdate(T update);
}

abstract class UpdatableArgsWidget extends UpdatableWidget<Map<String, dynamic>> {
  const UpdatableArgsWidget({super.key});
}

abstract class UpdatableArgsState<S extends UpdatableWidget<Map<String, dynamic>>>
    extends UpdatableState<Map<String, dynamic>, S> {}

abstract class HomeScreenPage extends UpdatableArgsWidget {
  const HomeScreenPage({super.key});
}

abstract class HomeScreenPageState<S extends UpdatableArgsWidget> extends UpdatableArgsState<S>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}
