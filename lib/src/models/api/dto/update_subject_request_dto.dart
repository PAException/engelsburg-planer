/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class UpdateSubjectRequestDTO {
  int subjectId;
  String? customName;
  String? color;
  bool? advancedCourse;

  UpdateSubjectRequestDTO({
    required this.subjectId,
    this.customName,
    this.color,
    this.advancedCourse = false,
  });

  dynamic toJson() => {
        "subjectId": subjectId,
        "customName": customName,
        "color": color,
        "advancedCourse": advancedCourse,
      };
}
