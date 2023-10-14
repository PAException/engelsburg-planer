/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/utils/firebase/analytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/routing/page.dart';

/// Basic configuration of the app.
/// Defines the appearance and the order of all the sections of the app.
class AppConfigState extends NullableStorableChangeNotifier<AppConfiguration> {
  AppConfigState() : super("app_configuration", AppConfiguration.fromJson) {
    if (isConfigured) Pages.userType = userType!;
  }

  bool get isConfigured => current != null;

  UserType? get userType => current?.userType;

  String? get extra => current?.extra;

  bool get isLowerGrade => userType == UserType.student && (extra?[0].isNumeric ?? false);

  Future<void> configure(AppConfiguration config) async {
    /// Extra has to be set of appType is student or teacher
    assert(config.userType == UserType.other || config.extra != null);

    Analytics.user.setAppConfig(config);
    current = config;
    await save(() => Pages.userType = userType!);
  }
}

/// The actual basic app configuration.
/// Holds information whether the user is a student, teacher or someone else.
/// If the user is a teacher [extra] contains the abbreviation.
/// If the user is a student [extra] contains the classname.
/// If the user is someone else [extra] is null.
class AppConfiguration {
  /// The type of the app
  UserType userType;

  /// Extra information about the app type. Only nullable on AppType.other!
  String? extra;

  AppConfiguration({
    required this.userType,
    required this.extra,
  });

  factory AppConfiguration.fromJson(dynamic json) => AppConfiguration(
        userType: AppTypeExt.parse(json["appType"]),
        extra: json["extra"],
      );

  dynamic toJson() => {
        "appType": userType.name,
        "extra": extra,
      };
}

/// Enum for [AppConfiguration]
enum UserType {
  student,
  teacher,
  other,
}

extension AppTypeExt on UserType {
  String get name {
    switch (this) {
      case UserType.student:
        return "student";
      case UserType.teacher:
        return "teacher";
      case UserType.other:
        return "other";
    }
  }

  static UserType parse(String name) {
    switch (name) {
      case "student":
        return UserType.student;
      case "teacher":
        return UserType.teacher;
      default:
        return UserType.other;
    }
  }
}
