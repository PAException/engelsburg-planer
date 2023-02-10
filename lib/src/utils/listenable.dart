/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/type_definitions.dart';

class Listenable<T> {
  final Set<Listener<T>> _listeners = <Listener<T>>{};
  T _t;

  Listenable(this._t);

  T get get => _t;

  /// Updates the current value and calls all listeners
  void update(T t) {
    _t = t;
    for (var listener in _listeners) {
      listener.call(t);
    }
  }

  void addListener(Listener<T> listener) => _listeners.add(listener);

  void removeListener(Listener<T> listener) => _listeners.remove(listener);
}
