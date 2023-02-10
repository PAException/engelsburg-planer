/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/semester.dart';
import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';

class SemesterState extends StorableChangeNotifier<SemesterSettings> {
  SemesterState() : super("semester", SemesterSettings.fromJson, SemesterSettings());

  bool get hasActive => current.currentSemesterId != null;

  Semester? _getSemester(int semesterId) =>
      current.semester.firstNullableWhere((e) => e.semesterId == semesterId);

  Semester? get active => hasActive ? _getSemester(current.currentSemesterId!) : null;

  void addSemester(Semester semester, {bool setActive = false}) {
    current.semester.add(semester);

    if (setActive) setActiveSemester(semester.semesterId);
    onlySave();
  }

  void removeSemester(int semesterId) {
    if (semesterId == current.currentSemesterId) return;

    current.semester.removeWhere((e) => e.semesterId == semesterId);
    onlySave();
  }

  void setActiveSemester(int semesterId) {
    if (_getSemester(semesterId) == null) return;

    current.currentSemesterId = semesterId;
    onlySave();
    notifyListeners();
  }
}
