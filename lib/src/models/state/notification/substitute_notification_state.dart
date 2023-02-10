/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/utils/switch.dart';

class SubstituteNotificationState extends StorableChangeNotifier<SubstituteNotificationSettings> {
  SubstituteNotificationState()
      : super(
          "settings_notification_substitute",
          SubstituteNotificationSettings.fromJson,
          SubstituteNotificationSettings.empty(),
        );

  bool get asSubstituteSettings => current.asSubstituteSettings;

  bool get byClasses => current.classes.enabled;

  bool get byTeacher => current.teacher.enabled;

  bool get timetable => current.timetable;

  List<String> get classes => current.classes.data;

  List<String> get teacher => current.teacher.data;

  set asSubstituteSettings(bool value) => save(() => current.asSubstituteSettings = value);

  set byClass(bool value) => save(() => current.classes.enabled = value);

  set byTeacher(bool value) => save(() => current.teacher.enabled = value);

  set byTimetable(bool value) => save(() => current.timetable = value);

  set classes(List<String> classes) => save(() => current.classes.data = classes);

  set teacher(List<String> teacher) => save(() => current.teacher.data = teacher);
}

class SubstituteNotificationSettings {
  bool asSubstituteSettings;
  ListSwitch<String> classes;
  ListSwitch<String> teacher;
  bool timetable;

  SubstituteNotificationSettings({
    required this.asSubstituteSettings,
    required this.classes,
    required this.teacher,
    required this.timetable,
  });

  SubstituteNotificationSettings.empty()
      : asSubstituteSettings = true,
        classes = ListSwitch<String>(),
        teacher = ListSwitch<String>(),
        timetable = false;

  factory SubstituteNotificationSettings.fromJson(dynamic json) {
    return SubstituteNotificationSettings(
      asSubstituteSettings: json["asSubstituteSettings"],
      classes: json["classes"],
      teacher: json["teacher"],
      timetable: json["timetable"],
    );
  }

  dynamic toJson() {
    return {
      "asSubstituteSettings": asSubstituteSettings,
      "classes": classes,
      "teacher": teacher,
      "timetable": timetable,
    };
  }
//
}
