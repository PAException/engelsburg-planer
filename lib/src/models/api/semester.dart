/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class Semester {
  int semesterId;
  int? schoolYear;
  int? semester;
  String? classSuffix;

  Semester({
    required this.semesterId,
    this.schoolYear,
    this.semester,
    this.classSuffix,
  });

  static List<Semester> fromSemester(dynamic json) {
    if (json is Map) json = json["semester"];

    return json.map<Semester>((e) => Semester.fromJson(e)).toList();
  }

  dynamic toJson() => {
        "semesterId": semesterId,
        "schoolYear": schoolYear,
        "semester": semester,
        "classSuffix": classSuffix,
      };

  factory Semester.fromJson(dynamic json) => Semester(
        semesterId: json["semesterId"],
        schoolYear: json["schoolYear"],
        semester: json["semester"],
        classSuffix: json["classSuffix"],
      );
}

class SemesterSettings {
  final List<Semester> semester;
  int? currentSemesterId;

  SemesterSettings({
    this.semester = const [],
    this.currentSemesterId,
  });

  factory SemesterSettings.fromJson(dynamic json) => SemesterSettings(
        semester: json["semester"].map<Semester>((e) => Semester.fromJson(e)).toList(),
        currentSemesterId: json["currentSemesterId"],
      );

  dynamic toJson() => {
        "semester": semester,
        "currentSemesterId": currentSemesterId,
      };
}
