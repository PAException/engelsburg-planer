/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class CreateSemesterRequestDTO {
  int semester;
  int? schoolYear;
  String? classSuffix;

  bool? setAsCurrentSemester;
  bool? copySubjects;
  bool? copyTimetable;
  bool? copyGradeShares;

  CreateSemesterRequestDTO({
    required this.semester,
    this.schoolYear, //Default will be current
    this.classSuffix,
    this.setAsCurrentSemester = true,
    this.copySubjects = true,
    this.copyTimetable = false,
    this.copyGradeShares = true,
  });

  dynamic toJson() => {
        "semester": semester,
        "schoolYear": schoolYear,
        "classSuffix": classSuffix,
        "setAsCurrentSemester": setAsCurrentSemester,
        "copySubjects": copySubjects,
        "copyTimetable": copyTimetable,
        "copyGradeShares": copyGradeShares,
      };
}
