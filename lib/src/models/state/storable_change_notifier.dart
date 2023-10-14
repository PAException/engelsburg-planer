/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/services/cache_service.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:flutter/foundation.dart';

/// ChangeNotifier that can be stored via [CacheService].
abstract class StorableChangeNotifier<T> extends ChangeNotifier {
  /// The key is to identify the saved data. Must be unique to avoid collisions.
  final String key;

  /// Current state of the stored object.
  @protected
  late T current;

  StorableChangeNotifier(this.key, Parser<T> parse, T onNull) {
    dynamic json = CacheService.getNullableJson(key);
    current = json != null ? parse(json) : onNull;
  }

  /// Must be called everytime after a change to update the storage. (Not after [remove]).
  ///
  /// Will call [notifyListeners] after completion.
  @nonVirtual
  Future<void> save([VoidCallback? execute]) async {
    if (execute != null) execute.call();
    notifyListeners();

    await onlySave();
  }

  /// Only performs save operation, no notify or executions
  @nonVirtual
  Future<void> onlySave() async => await CacheService.setJson(key, current);

  /// Clears all current data and replaces it with [empty].
  @nonVirtual
  Future<void> clear(T empty) async {
    current = empty;
    notifyListeners();

    await CacheService.remove(key);
  }
}

/// ChangeNotifier that can be stored via [CacheService].
abstract class NullableStorableChangeNotifier<T> extends StorableChangeNotifier<T?> {
  NullableStorableChangeNotifier(String key, Parser<T> parse) : super(key, parse, null);

  /// Remove everything in the storage associated to the [key] and clear current.
  /// Will automatically call [notifyListeners] after completion.
  @nonVirtual
  Future<void> remove() async {
    current = null;
    notifyListeners();

    await CacheService.remove(key);
  }
}
