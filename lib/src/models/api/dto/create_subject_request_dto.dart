/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/subject.dart';

class CreateSubjectRequestDTO {
  String baseSubject;
  String? customName;
  String color;
  bool advancedCourse;

  CreateSubjectRequestDTO({
    required this.baseSubject,
    this.customName,
    required this.color,
    this.advancedCourse = false,
  });

  dynamic toJson() => {
        "baseSubject": baseSubject,
        "customName": customName,
        "color": color,
        "advancedCourse": advancedCourse,
      };

  Subject toSubject() {
    return Subject(
      baseSubject: baseSubject,
      customName: customName,
      color: color,
      advancedCourse: advancedCourse,
    );
  }
}
