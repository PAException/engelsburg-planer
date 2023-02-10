/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class UpdateSemesterRequestDTO {
  int semesterId;
  int? schoolYear;
  int? semester;
  String? classSuffix;

  UpdateSemesterRequestDTO({
    required this.semesterId,
    this.schoolYear,
    this.semester,
    this.classSuffix,
  });

  dynamic toJson() => {
        "semesterId": semesterId,
        "schoolYear": schoolYear,
        "semester": semester,
        "classSuffix": classSuffix,
      };
}
