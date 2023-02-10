/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';

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

class AppConfigurationState extends NullableStorableChangeNotifier<AppConfiguration> {
  AppConfigurationState() : super("app_configuration", AppConfiguration.fromJson) {
    if (isConfigured) Pages.appType = appType!;
  }

  bool get isConfigured => current != null;

  AppType? get appType => current?.appType;

  Future<void> configure(AppConfiguration config) async {
    /// Extra has to be set of appType is student or teacher
    assert(config.appType == AppType.other || config.extra != null);

    current = config;
    await save(() => Pages.appType = appType!);
  }
}

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
