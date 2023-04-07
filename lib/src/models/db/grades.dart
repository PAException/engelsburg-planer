/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class Grades {
  Grades({
    required this.usePoints,
    required this.roundEachType,
  });

  bool usePoints; // Default if className starts not with number
  bool roundEachType; // Default false

  static GradesSchema get([bool online = storeOnline]) => online ? OnlineGrades() : OfflineGrades();

  factory Grades.fromJson(Map<String, dynamic> json) => Grades(
        usePoints:
            json["usePoints"] ?? !globalContext().read<AppConfigState>().isLowerGrade ?? false,
        roundEachType: json["roundEachType"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "usePoints": usePoints,
        "roundEachType": roundEachType,
      };
}

abstract class GradesSchema extends Document<Grades> {
  GradesSchema();

  Collection<Document<Grade>, Grade> get entries;
}

class OnlineGrades extends OnlineDocument<Grades> implements GradesSchema {
  OnlineGrades() : super(documentReference: doc, fromJson: Grades.fromJson);

  static DocumentReference<Map<String, dynamic>> doc() =>
      FirebaseFirestore.instance.collection("grades").doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  Collection<Document<Grade>, Grade> get entries => OnlineCollection<OnlineDocument<Grade>, Grade>(
        collection: () => document.collection("entries"),
        buildType: (doc) => OnlineDocument(
          documentReference: () => doc,
          fromJson: Grade.fromJson,
        ),
      );
}

class OfflineGrades extends OfflineDocument<Grades> implements GradesSchema {
  OfflineGrades() : super(key: "grades", fromJson: Grades.fromJson);

  @override
  Collection<Document<Grade>, Grade> get entries =>
      OfflineCollection<OfflineDocument<Grade>, Grade>(
        parent: this,
        collection: "entries",
        buildType: (id, parent) => OfflineDocument(
          parent: parent,
          key: id,
          fromJson: Grade.fromJson,
        ),
      );
}

class Grade {
  Document<Subject> subject;
  int gradeType;
  DateTime created;
  int? points;
  int? grade;
  String? name;

  Grade({
    required this.subject,
    required this.gradeType,
    required this.created,
    this.points,
    this.grade,
    this.name,
  }) : assert((grade != null) ^ (points != null));

  int value([bool? usePoints]) {
    usePoints ??= true;
    if (points != null) return usePoints ? points! : pointsToGrade(points!);

    return usePoints ? gradeToPoints(grade!) : grade!;
  }

  static int pointsToGrade(int points) => ((points / 3).ceil() * -1).round() + 6;

  static int gradeToPoints(int grade) => max(0, (((grade - 6) * -1) * 3) - 1);

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        subject: Subjects.get().entries[json["subject"]],
        gradeType: json["gradeType"],
        created: DateTime.fromMillisecondsSinceEpoch(json["timestamp"]),
        points: json["points"],
        name: json["name"],
      );

  Map<String, dynamic> toJson() => {
        "subject": subject.id,
        "gradeType": gradeType,
        "timestamp": created.millisecondsSinceEpoch,
        "points": points,
        "name": name,
      };

  @override
  String toString() {
    return 'Grade{subject: $subject, gradeType: $gradeType, created: $created, points: $points, name: $name}';
  }
}

class GradeType {
  String name;
  double share;

  GradeType({
    required this.name,
    required this.share,
  });

  factory GradeType.fromJson(Map<String, dynamic> json) => GradeType(
        name: json["name"],
        share: json["share"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "share": share,
      };

  @override
  bool operator ==(Object other) =>
      other is GradeType && name == other.name && share == other.share;

  @override
  int get hashCode => name.hashCode ^ share.hashCode;
}
