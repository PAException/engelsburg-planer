/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:flutter/material.dart';

class Subjects {
  Subjects();

  static DocumentReference<Subjects> ref() => const DocumentReference<Subjects>("subjects", Subjects.fromJson);

  static CollectionReference<Subject> entries() => ref().collection<Subject>("entries", Subject.fromJson);

  Map<String, dynamic> toJson() => {};

  factory Subjects.fromJson(Map<String, dynamic> json) => Subjects();
}

/// Class that holds all information about a subject.
class Subject extends Comparable<Subject> {
  static const Color defaultColor = Colors.lightBlueAccent;
  static const String defaultColorString = "#FF40C4FF";

  final String baseSubject;
  String? customName;
  String color;
  bool advancedCourse;
  late List<GradeType> _gradeTypes;

  factory Subject.fromBaseSubject(String baseSubject) => Subject(baseSubject, []);

  Subject(
    this.baseSubject,
    this._gradeTypes, {
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
      customName ?? BaseSubject.get(this).l10n(context) ?? baseSubject;

  List<GradeType> getGradeTypes(BuildContext context) => _gradeTypes.isNotEmpty
      ? _gradeTypes
      : _gradeTypes = _defaultGradeTypes(context);

  static List<GradeType> _defaultGradeTypes(BuildContext context) => [
    GradeType(name: context.l10n.oralGrade, share: 0.5),
    GradeType(name: context.l10n.exam, share: 0.5),
  ];

  set gradeTypes(List<GradeType> gradeTypes) => _gradeTypes = gradeTypes;

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        json["baseSubject"],
        (json["gradeTypes"] as List?)
            ?.map<GradeType>((e) => GradeType.fromJson(e.cast<String, dynamic>()))
            .toList() ?? [],
        customName: json["customName"],
        color: json["color"] ?? defaultColorString,
        advancedCourse: json["advancedCourse"],
      );

  Map<String, dynamic> toJson() => {
        "baseSubject": baseSubject,
        "customName": customName,
        "color": color,
        "advancedCourse": advancedCourse,
        "gradeTypes": _gradeTypes.map((e) => e.toJson()).toList(),
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

  static final Map<String, String> _baseSubjects = {
    "biology": "SCIENTIFIC",
    "chemistry": "SCIENTIFIC",
    "informatics": "SCIENTIFIC",
    "math": "SCIENTIFIC",
    "physics": "SCIENTIFIC",
    "ethics": "SOCIAL_SCIENTIFIC",
    "geography": "SOCIAL_SCIENTIFIC",
    "history": "SOCIAL_SCIENTIFIC",
    "philosophy": "SOCIAL_SCIENTIFIC",
    "psychology": "SOCIAL_SCIENTIFIC",
    "religion": "SOCIAL_SCIENTIFIC",
    "economics": "SOCIAL_SCIENTIFIC",
    "german": "LINGUISTICALLY_LITERARY",
    "art": "LINGUISTICALLY_LITERARY",
    "music": "LINGUISTICALLY_LITERARY",
    "english": "FOREIGN_LINGUISTICALLY",
    "french": "FOREIGN_LINGUISTICALLY",
    "greek": "FOREIGN_LINGUISTICALLY",
    "italian": "FOREIGN_LINGUISTICALLY",
    "latin": "FOREIGN_LINGUISTICALLY",
    "spanish": "FOREIGN_LINGUISTICALLY",
    "sport": "OTHER",
  };

  static BaseSubject get(Subject subject) => BaseSubject(
        name: subject.baseSubject,
        group: _baseSubjects[subject.baseSubject] ?? "OTHER",
      );

  static List<BaseSubject> getAll() =>
      _baseSubjects.mapToList((key, value) => BaseSubject(name: key, group: value));

  String? l10n(BuildContext context) {
    switch (name) {
      case "biology":
        return context.l10n.biology;
      case "chemistry":
        return context.l10n.chemistry;
      case "informatics":
        return context.l10n.informatics;
      case "math":
        return context.l10n.math;
      case "physics":
        return context.l10n.physics;
      case "ethics":
        return context.l10n.ethics;
      case "geography":
        return context.l10n.geography;
      case "history":
        return context.l10n.history;
      case "philosophy":
        return context.l10n.philosophy;
      case "psychology":
        return context.l10n.psychology;
      case "religion":
        return context.l10n.religion;
      case "economics":
        return context.l10n.economics;
      case "german":
        return context.l10n.german;
      case "art":
        return context.l10n.art;
      case "music":
        return context.l10n.music;
      case "english":
        return context.l10n.english;
      case "french":
        return context.l10n.french;
      case "greek":
        return context.l10n.greek;
      case "italian":
        return context.l10n.italian;
      case "latin":
        return context.l10n.latin;
      case "spanish":
        return context.l10n.spanish;
      case "sport":
        return context.l10n.sport;
    }

    return null;
  }

  String l10nGroup(BuildContext context) {
    switch (group) {
      case "SCIENTIFIC":
        return context.l10n.science;
      case "SOCIAL_SCIENTIFIC":
        return context.l10n.socialScience;
      case "LINGUISTICALLY_LITERARY":
        return context.l10n.linguisticallyLiterary;
      case "FOREIGN_LINGUISTICALLY":
        return context.l10n.foreignLanguage;
      default: //OTHER
        return context.l10n.other;
    }
  }

  @override
  String toString() {
    return 'BaseSubject{name: $name, group: $group}';
  }
}
