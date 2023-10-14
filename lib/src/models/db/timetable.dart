/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';

class Timetable {
  bool shared;

  Timetable({
    this.shared = false,
  });

  static DocumentReference<Timetable> ref() =>
      const DocumentReference<Timetable>("timetable", Timetable.fromJson);

  static CollectionReference<TimetableEntry> entries() =>
      ref().collection<TimetableEntry>("entries", TimetableEntry.fromJson);

  Json toJson() => {"shared": shared};

  factory Timetable.fromJson(Json json) => Timetable(
        shared: json["shared"] ?? false,
      );
}

class TimetableEntry implements Comparable<TimetableEntry> {
  final int day;
  final int lesson;
  String? teacher;
  String? className;
  String? room;
  DocumentReference<Subject>? subject;

  TimetableEntry({
    required this.day,
    required this.lesson,
    this.teacher,
    this.className,
    this.room,
    this.subject,
  });

  factory TimetableEntry.fromJson(Json json) => TimetableEntry(
        day: json["day"],
        lesson: json["lesson"],
        teacher: json["teacher"],
        className: json["className"],
        room: json["room"],
        subject: json["subject"] != null ? Subjects.entries().doc(json["subject"]) : null,
      );

  Json toJson() => {
        "day": day,
        "lesson": lesson,
        "teacher": teacher,
        "className": className,
        "room": room,
        "subject": subject?.id,
      };

  bool get isEmpty => (teacher?.isEmpty ?? true)
      && (className?.isEmpty ?? true)
      && (room?.isEmpty ?? true)
      && subject == null;

  bool sameTime(TimetableEntry? other) =>
      other != null &&
      other.day == day &&
      other.lesson == lesson;

  @override
  int compareTo(TimetableEntry other) {
    if (day != other.day) return (day < other.day) ? -1 : 1;
    if (lesson != other.lesson) return (lesson < other.lesson) ? -1 : 1;

    return 0;
  }

  @override
  String toString() {
    return 'TimetableEntry{day: $day, lesson: $lesson, teacher: $teacher, className: $className, room: $room, subjectId: $subject}';
  }
}
