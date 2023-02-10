/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/controller/article_controller.dart';
import 'package:engelsburg_planer/src/controller/subject_controller.dart';
import 'package:engelsburg_planer/src/controller/timetable_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A service to manage a specific part of data
class DataService {
  static Map<Type, DataService>? _services;
  late BuildContext context;

  ///Gets called on application start
  Future<void> setup() async {}

  @nonVirtual
  void updateContext(BuildContext context) => this.context = context;

  /// Get services and call setup() on them
  static void initialize(BuildContext context) {
    _services = _initServices();

    for (var controller in _services!.values) {
      controller
        ..updateContext(context)
        ..setup();
    }
  }

  /// Parse all services in a map with types
  static Map<Type, DataService> _initServices() {
    final List<DataService> services = [
      ArticleService(),
      //TODO SubstituteService(),
      TimetableService(),
      SubjectService(),
    ];

    return services.asMap().map((_, service) => MapEntry(service.runtimeType, service));
  }

  /// Get a service by type with a BuildContext
  /// Cannot be called before init(BuildContext)
  /// Throws error if T was not initialized
  static T of<T extends DataService>(BuildContext context) {
    if (_services == null) throw StateError("DataServices are not initialized!");
    if (!_services!.containsKey(T)) throw ArgumentError("$T is not a supported service");

    return (_services![T]!..updateContext(context)) as T;
  }
}

/// Shortcut on BuildContext to get data service
extension DataServiceUtils on BuildContext {
  T? data<T extends DataService>() => DataService.of<T>(this);
}

/// Shortcut to get a data service in a Widget
mixin DataStateMixin<T extends DataService> {
  T get dataService => DataService.of<T>((this as dynamic).context);
}
