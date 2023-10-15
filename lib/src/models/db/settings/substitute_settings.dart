/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/timetable.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:provider/provider.dart';

class SubstituteSettings {
  String? password;

  bool byClasses;
  List<String> classes;

  bool byTeacher;
  List<String> teacher;

  bool byTimetable;

  SubstituteSettings({
    this.password,
    required this.byClasses,
    required this.classes,
    required this.byTeacher,
    required this.teacher,
    required this.byTimetable,
  });

  /// Creates new substitute settings.
  /// If app type student or teacher is specified, the settings
  /// will be customized by default.
  factory SubstituteSettings.empty() {
    var config = globalContext().read<AppConfigState>();
    bool byClasses = false;
    List<String> classes = [];
    bool byTeacher = false;
    List<String> teacher = [];
    bool byTimetable = false;

    if (config.userType == UserType.student) {
      byClasses = true;
      classes.add(config.extra!);
      byTimetable = true;
    } else if (config.userType == UserType.teacher) {
      byTeacher = true;
      teacher.add(config.extra!);
      byTimetable = true;
    }

    return SubstituteSettings(
      byClasses: byClasses,
      classes: classes,
      byTeacher: byTeacher,
      teacher: teacher,
      byTimetable: byTimetable,
    );
  }

  /// Get priority topics to send notification settings to API if enabled.
  Future<List<String>> priorityTopics() async {
    var priorityTopics = [
      if (byClasses)
        ...classes.map((className) => "substitute.class.$className"),
      if (byTeacher)
        ...teacher.map((teacher) => "substitute.teacher.$teacher"),
    ];

    if (byTimetable) {
      var entries =
          await Timetable.entries().defaultStorage(globalContext()).documents();
      var timetableTopics = entries.map((entry) {
        var day = entry.data!.day;
        var lesson = entry.data!.lesson;
        var teacher = entry.data!.teacher?.toUpperCase();
        var className = entry.data!.className?.toUpperCase();

        if (teacher != null && teacher.isNotEmpty) {
          return "substitute.timetable.$day.$lesson.$teacher";
        } else if (className != null && className.isNotEmpty) {
          return "substitute.timetable.$day.$lesson.$className";
        } else {
          return "";
        }
      });

      //Remove empty entries
      priorityTopics.addAll(timetableTopics.where((e) => e != ""));
    }

    if (priorityTopics.isEmpty) priorityTopics.add("substitute");
    return priorityTopics;
  }

  static DocumentReference<SubstituteSettings> ref() =>
      const DocumentReference<SubstituteSettings>(
          "substitute_settings", SubstituteSettings.fromJson);

  factory SubstituteSettings.fromJson(Map<String, dynamic> json) => json.isEmpty
      ? SubstituteSettings.empty()
      : SubstituteSettings(
          password: json["password"],
          byClasses: json["byClasses"] ?? false,
          classes: List.of(json["classes"] ?? []).cast<String>().toList(),
          byTeacher: json["byTeacher"] ?? false,
          teacher: List.of(json["teacher"] ?? []).cast<String>().toList(),
          byTimetable: json["byTimetable"] ?? false,
        );

  Map<String, dynamic> toJson() => {
        "password": password,
        "byClasses": byClasses,
        "classes": classes,
        "byTeacher": byTeacher,
        "teacher": teacher,
        "byTimetable": byTimetable,
      };
}
