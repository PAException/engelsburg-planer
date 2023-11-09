/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:math';

import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:provider/provider.dart';

class Grades {
  Grades({
    required this.usePoints,
    required this.roundEachType,
  });

  bool usePoints; // Default if className starts not with number
  bool roundEachType; // Default false

  static DocumentReference<Grades> ref() =>
      const DocumentReference<Grades>("grades", Grades.fromJson);

  static CollectionReference<Grade> entries() =>
      ref().collection<Grade>("entries", Grade.fromJson);

  factory Grades.fromJson(Map<String, dynamic> json) => json.isEmpty ? Grades.empty() : Grades(
    usePoints: json["usePoints"] ?? false,
    roundEachType: json["roundEachType"] ?? false,
  );

  factory Grades.empty() {
    var appConfig = globalContext().read<AppConfigState>();

    return Grades(usePoints: !appConfig.isLowerGrade, roundEachType: false);
  }

  Map<String, dynamic> toJson() => {
    "usePoints": usePoints,
    "roundEachType": false,
  };
}

class Grade {
  DocumentReference<Subject> subject;
  int gradeType;
  DateTime created;
  int points;
  String? name;

  Grade({
    required this.subject,
    required this.gradeType,
    required this.created,
    required this.points,
    this.name,
  });

  int value([bool? usePoints]) {
    usePoints ??= true;

    return usePoints ? points : pointsToGrade(points);
  }

  static int pointsToGrade(int points) => ((points / 3).ceil() * -1).round() + 6;

  static int gradeToPoints(int grade) => max(0, (((grade - 6) * -1) * 3) - 1);

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
        subject: Subjects.entries().doc(json["subject"]),
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
