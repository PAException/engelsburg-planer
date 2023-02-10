/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';

class NotificationSettingsState extends StorableChangeNotifier<NotificationSettings> {
  NotificationSettingsState()
      : super(
          "settings_notification",
          NotificationSettings.fromJson,
          NotificationSettings.empty(),
        );

  bool get enabled => current.enabled;

  bool get article => current.article && enabled;

  bool get substitute => current.substitute && enabled;
}

class NotificationSettings {
  bool enabled;
  bool article;
  bool substitute;

  NotificationSettings({
    required this.enabled,
    required this.article,
    required this.substitute,
  });

  NotificationSettings.empty()
      : enabled = true,
        article = true,
        substitute = true;

  factory NotificationSettings.fromJson(dynamic json) {
    return NotificationSettings(
      enabled: json["enabled"],
      article: json["article"],
      substitute: json["substitute"],
    );
  }

  dynamic toJson() {
    return {
      "enabled": enabled,
      "article": article,
      "substitute": substitute,
    };
  }
}
