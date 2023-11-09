/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class Teachers {
  final List<Teacher> teachers;

  Teachers({required this.teachers});

  factory Teachers.fromJson(dynamic json) => Teachers(
      teachers: (json["teachers"] as List).map<Teacher>(
              (e) => Teacher.fromJson(e.cast<String, dynamic>())
      ).toList(),
  );

  Map<String, dynamic> toJson() => {
      "teachers": teachers,
    };
}

class Teacher {
  final String abbreviation;
  final String firstname;
  final String surname;
  final String gender;
  final bool mentionedPhD;
  final List<String> jobs;

  Teacher({
    required this.abbreviation,
    required this.firstname,
    required this.surname,
    required this.gender,
    required this.mentionedPhD,
    this.jobs = const [],
  });

  String parsedName() => "${gender == "female" ? "Frau" : "Herr"} ${mentionedPhD ? "Dr. " : ""}$surname";

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    abbreviation: json["abbreviation"],
    firstname: json["firstname"],
    surname: json["surname"],
    gender: json["gender"],
    mentionedPhD: json["mentionedPhD"],
    //TODO JOBS
  );

  Map<String, dynamic> toJson() => {
    "abbreviation": abbreviation,
    "firstname": firstname,
    "surname": surname,
    "gender": gender,
    "mentionedPhD": mentionedPhD,
    "jobs": jobs,
  };
}

