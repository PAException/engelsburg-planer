/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class TimetableEntry implements Comparable<TimetableEntry> {
  final int day;
  final int lesson;
  String? teacher;
  String? className;
  String? room;
  int? subjectId;

  TimetableEntry({
    required this.day,
    required this.lesson,
    this.teacher,
    this.className,
    this.room,
    this.subjectId,
  });

  static List<TimetableEntry> fromEntries(dynamic json) =>
      List<TimetableEntry>.from(json["entries"].map(TimetableEntry.fromJson));

  factory TimetableEntry.fromJson(dynamic json) => TimetableEntry(
        day: json["day"],
        lesson: json["lesson"],
        teacher: json["teacher"],
        className: json["className"],
        room: json["room"],
        subjectId: json["subjectId"],
      );

  dynamic toJson() => {
        "day": day,
        "lesson": lesson,
        "teacher": teacher,
        "className": className,
        "room": room,
        "subjectId": subjectId,
      };

  bool equalData(TimetableEntry? other) =>
      other != null &&
      other.teacher == teacher &&
      other.className == className &&
      other.room == room &&
      other.subjectId == subjectId;

  @override
  int compareTo(TimetableEntry other) {
    if (day != other.day) return (day < other.day) ? -1 : 1;
    if (lesson != other.lesson) return (lesson < other.lesson) ? -1 : 1;

    return 0;
  }

  @override
  String toString() {
    return 'TimetableEntry{day: $day, lesson: $lesson, teacher: $teacher, className: $className, room: $room, subjectId: $subjectId}';
  }
}
