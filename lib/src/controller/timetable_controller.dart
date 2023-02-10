/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/timetable.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';

class TimetableService extends DataService {
  final List<TimetableEntry> _timetable = [];

  void _addEntry(TimetableEntry entry) => _timetable.add(entry);

  TimetableEntry getEntry(int day, int lesson) => _timetable.firstWhere(
        (entry) => entry.day == day && entry.lesson == lesson,
        orElse: () => TimetableEntry(day: day, lesson: lesson),
      );

  void _removeEntry(int day, int lesson) =>
      _timetable.removeWhere((entry) => entry.day == day && entry.lesson == lesson);

  @override
  Future<void> setup() async {}

  TimetableEntry? updateTimetable({
    required int day,
    required int lesson,
    int? subjectId,
    String? teacher,
    String? className,
    String? room,
  }) {
    if (subjectId == null) {
      _removeEntry(day, lesson);
      return null;
    }

    final entry = getEntry(day, lesson);
    entry.subjectId = subjectId;
    if (teacher != null && teacher != entry.teacher) {
      entry.teacher = teacher;
    }
    if (className != null && className != entry.className) {
      entry.className = className;
    }
    if (room != null && room != entry.room) {
      entry.room = room;
    }

    _removeEntry(day, lesson);
    _addEntry(entry);

    return entry;
  }

  Future<List<TimetableEntry>> getTimetable(DateTime? dateTime) async {
    if (dateTime == null) return List.of(_timetable);

    return _timetable.where((entry) => entry.day == dateTime.weekday).toList();
  }
}
