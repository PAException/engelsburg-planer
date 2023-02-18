/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/controller/subject_controller.dart';
import 'package:engelsburg_planer/src/controller/timetable_controller.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Subjects {
  Subjects();

  static SubjectsSchema get online => SubjectsOnline();

  static SubjectsSchema get offline => SubjectsOffline();

  Map<String, dynamic> toJson() => {};

  factory Subjects.fromJson(Map<String, dynamic> json) => Subjects();
}

abstract class SubjectsSchema extends Document<Subjects> {
  Collection<Document<Subject>, Subject> get subjects;
}

class SubjectsOnline extends OnlineDocument<Subjects> implements SubjectsSchema {
  SubjectsOnline() : super(documentReference: doc, fromJson: Subjects.fromJson);

  static DocumentReference<Map<String, dynamic>> doc() =>
      FirebaseFirestore.instance.collection("subjects").doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  Collection<Document<Subject>, Subject> get subjects =>
      OnlineCollection<OnlineDocument<Subject>, Subject>(
        collection: () => document.collection("subjects"),
        buildType: (doc) => OnlineDocument(
          documentReference: () => doc,
          fromJson: Subject.fromJson,
        ),
      );
}

class SubjectsOffline extends OfflineDocument<Subjects> implements SubjectsSchema {
  SubjectsOffline() : super(key: "subjects", fromJson: Subjects.fromJson);

  @override
  Collection<Document<Subject>, Subject> get subjects =>
      OfflineCollection<OfflineDocument<Subject>, Subject>(
        parent: this,
        collection: "subjects",
        buildType: (id) => OfflineDocument(
          key: id,
          fromJson: Subject.fromJson,
        ),
      );
}

/// Class that holds all information about a subject.
class Subject extends Comparable<Subject> {
  static const Color defaultColor = Colors.lightBlueAccent;
  static const String defaultColorString = "#FF40C4FF";

  final String baseSubject;
  String? customName;
  String color;
  bool advancedCourse;

  Subject({
    required this.baseSubject,
    this.customName,
    this.color = defaultColorString, //defaultColor
    this.advancedCourse = false,
  });

  static List<Subject> fromSubjects(dynamic json) =>
      json["subjects"].map<Subject>((e) => Subject.fromJson(e)).toList();

  /// Get color of subject or return default color
  Color get parsedColor => ColorUtils.fromHex(color) ?? Subject.defaultColor;

  /// Get name of subject. Name will be determined in the following order:
  /// - custom name of the subject
  /// - localization of the base subject
  /// - if both null return the plain base subject string
  String parsedName(BuildContext context) =>
      customName ??
      context.data<SubjectService>()!.getBaseSubject(this).localization(context) ??
      baseSubject;

  factory Subject.fromJson(dynamic json) => Subject(
        baseSubject: json["baseSubject"],
        customName: json["customName"],
        color: json["color"] ?? defaultColorString,
        advancedCourse:
            (json["advancedCourse"] is bool) ? json["advancedCourse"] : json["advancedCourse"] == 1,
      );

  dynamic toJson() => {
        "baseSubject": baseSubject,
        "customName": customName,
        "color": color,
        "advancedCourse": advancedCourse ? 1 : 0,
      };

  @override
  int compareTo(Subject other) {
    if (!advancedCourse && other.advancedCourse) return 1;
    if (advancedCourse && !other.advancedCourse) return -1;

    return 0;
  }

  @override
  String toString() {
    return 'Subject{baseSubject: $baseSubject, customName: $customName, color: $color, advancedCourse: $advancedCourse}';
  }
}

class BaseSubject {
  final String name;
  final String group;

  BaseSubject({
    required this.name,
    required this.group,
  });

  static List<BaseSubject> fromBaseSubjects(dynamic json) {
    if (json is Map) json = json["baseSubjects"];

    return json.map<BaseSubject>((e) => BaseSubject.fromJson(e)).toList();
  }

  factory BaseSubject.fromJson(dynamic json) => BaseSubject(
        name: json["name"],
        group: json["group"],
      );

  dynamic toJson() => {"name": name, "group": group};

  String? localization(BuildContext context) {
    switch (name) {
      case "biology":
        return AppLocalizations.of(context)!.biology;
      case "chemistry":
        return AppLocalizations.of(context)!.chemistry;
      case "informatics":
        return AppLocalizations.of(context)!.informatics;
      case "math":
        return AppLocalizations.of(context)!.math;
      case "physics":
        return AppLocalizations.of(context)!.physics;
      case "ethics":
        return AppLocalizations.of(context)!.ethics;
      case "geography":
        return AppLocalizations.of(context)!.geography;
      case "history":
        return AppLocalizations.of(context)!.history;
      case "philosophy":
        return AppLocalizations.of(context)!.philosophy;
      case "psychology":
        return AppLocalizations.of(context)!.psychology;
      case "religion":
        return AppLocalizations.of(context)!.religion;
      case "economics":
        return AppLocalizations.of(context)!.economics;
      case "german":
        return AppLocalizations.of(context)!.german;
      case "art":
        return AppLocalizations.of(context)!.art;
      case "music":
        return AppLocalizations.of(context)!.music;
      case "english":
        return AppLocalizations.of(context)!.english;
      case "french":
        return AppLocalizations.of(context)!.french;
      case "greek":
        return AppLocalizations.of(context)!.greek;
      case "italian":
        return AppLocalizations.of(context)!.italian;
      case "latin":
        return AppLocalizations.of(context)!.latin;
      case "spanish":
        return AppLocalizations.of(context)!.spanish;
      case "sport":
        return AppLocalizations.of(context)!.sport;
    }

    return null;
  }

  @override
  String toString() {
    return 'BaseSubject{name: $name, group: $group}';
  }
}
