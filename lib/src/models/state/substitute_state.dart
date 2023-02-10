/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/utils/switch.dart';

/// Provided state to keep track of the current substitute settings.
class SubstituteSettingsState extends StorableChangeNotifier<SubstituteSettings> {
  SubstituteSettingsState()
      : super(
          "settings_substitute",
          SubstituteSettings.fromJson,
          SubstituteSettings.empty(),
        );

  bool get byClasses => current.classes.enabled;

  bool get byTeacher => current.teacher.enabled;

  bool get timetable => current.timetable;

  List<String> get classes => current.classes.data;

  List<String> get teacher => current.teacher.data;

  set byClass(bool value) => save(() => current.classes.enabled = value);

  set byTeacher(bool value) => save(() => current.teacher.enabled = value);

  set byTimetable(bool value) => save(() => current.timetable = value);

  set classes(List<String> classes) => save(() => current.classes.data = classes);

  set teacher(List<String> teacher) => save(() => current.teacher.data = teacher);
}

/// Class to save substitute settings to storage.
class SubstituteSettings {
  ListSwitch<String> classes;
  ListSwitch<String> teacher;
  bool timetable;

  SubstituteSettings({
    required this.classes,
    required this.teacher,
    required this.timetable,
  });

  SubstituteSettings.empty()
      : classes = ListSwitch<String>(),
        teacher = ListSwitch<String>(),
        timetable = false;

  factory SubstituteSettings.fromJson(dynamic json) {
    return SubstituteSettings(
      classes: json["classes"],
      teacher: json["teacher"],
      timetable: json["timetable"],
    );
  }

  dynamic toJson() {
    return {
      "classes": classes,
      "teacher": teacher,
      "timetable": timetable,
    };
  }
}
