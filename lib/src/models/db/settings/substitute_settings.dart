/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/models/db/timetable.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class OnlineSubstituteSettings extends OnlineDocument<SubstituteSettings> {
  OnlineSubstituteSettings() : super(documentReference: doc, fromJson: SubstituteSettings.fromJson);

  static DocumentReference<Map<String, dynamic>> doc() => FirebaseFirestore.instance
      .collection("substituteSettings")
      .doc(FirebaseAuth.instance.currentUser!.uid);
}

class OfflineSubstituteSettings extends OfflineDocument<SubstituteSettings> {
  OfflineSubstituteSettings()
      : super(key: "substituteSettings", fromJson: SubstituteSettings.fromJson);
}

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

  factory SubstituteSettings.empty() {
    var config = globalContext().read<AppConfigState>();
    bool byClasses = false;
    List<String> classes = [];
    bool byTeacher = false;
    List<String> teacher = [];
    bool byTimetable = false;

    if (config.appType! == AppType.student) {
      byClasses = true;
      classes.add(config.extra!);
      byTimetable = true;
    } else if (config.appType! == AppType.teacher) {
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

  Future<List<String>> priorityTopics() async {
    return [
      if (byClasses) ...classes.map((className) => "substitute.class.$className"),
      if (byTeacher) ...teacher.map((teacher) => "substitute.teacher.$teacher"),
      if (byTimetable)
        ...await Timetable.get().entries.loadedItems.then((e) => e.map((entry) {
              var day = entry.day;
              var lesson = entry.lesson;
              var teacher = entry.teacher?.toUpperCase();
              var className = entry.className?.toUpperCase();

              if (teacher != null && teacher.isNotEmpty) {
                return "substitute.timetable.$day.$lesson.$teacher";
              } else if (className != null && className.isNotEmpty) {
                return "substitute.timetable.$day.$lesson.$className";
              } else {
                return "";
              }
            }).where((e) => e != "")),
    ];
  }

  static Document<SubstituteSettings> get([bool online = storeOnline]) =>
      online ? OnlineSubstituteSettings() : OfflineSubstituteSettings();

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
