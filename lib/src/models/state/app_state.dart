/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';

/// Basic configuration of the app.
/// Defines the appearance and the order of all the sections of the app.
class AppConfigState extends NullableStorableChangeNotifier<AppConfiguration> {
  AppConfigState() : super("app_configuration", AppConfiguration.fromJson) {
    if (isConfigured) Pages.appType = appType!;
  }

  bool get isConfigured => current != null;

  AppType? get appType => current?.appType;

  String? get extra => current?.extra;

  bool get isLowerGrade => appType == AppType.student && (extra?.startsWith("[0-9]") ?? false);

  Future<void> configure(AppConfiguration config) async {
    /// Extra has to be set of appType is student or teacher
    assert(config.appType == AppType.other || config.extra != null);

    current = config;
    await save(() => Pages.appType = appType!);
  }
}

/// The actual basic app configuration.
/// Holds information whether the user is a student, teacher or someone else.
/// If the user is a teacher [extra] contains the abbreviation.
/// If the user is a student [extra] contains the classname.
/// If the user is someone else [extra] is null.
class AppConfiguration {
  /// The type of the app
  AppType appType;

  /// Extra information about the app type. Only nullable on AppType.other!
  String? extra;

  AppConfiguration({
    required this.appType,
    required this.extra,
  });

  factory AppConfiguration.fromJson(dynamic json) => AppConfiguration(
        appType: AppTypeExt.parse(json["appType"]),
        extra: json["extra"],
      );

  dynamic toJson() => {
        "appType": appType.name,
        "extra": extra,
      };
}

/// Enum for [AppConfiguration]
enum AppType {
  student,
  teacher,
  other,
}

extension AppTypeExt on AppType {
  String get name {
    switch (this) {
      case AppType.student:
        return "student";
      case AppType.teacher:
        return "teacher";
      case AppType.other:
        return "other";
    }
  }

  static AppType parse(String name) {
    switch (name) {
      case "student":
        return AppType.student;
      case "teacher":
        return AppType.teacher;
      default:
        return AppType.other;
    }
  }
}
