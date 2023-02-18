/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/controller/timetable_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/type_definitions.dart';

class Timetable {
  bool shared;

  Timetable({
    this.shared = false,
  });

  static TimetableSchema get offline => TimetableOffline();

  static TimetableSchema get online => TimetableOnline();

  Json toJson() {
    return {
      "shared": shared,
    };
  }

  factory Timetable.fromJson(Json json) {
    return Timetable(
      shared: json["shared"].toLowerCase() == 'true',
    );
  }
}

abstract class TimetableSchema extends Document<Timetable> {
  Collection<Document<TimetableEntry>, TimetableEntry> get entries;
}

class TimetableOnline extends OnlineDocument<Timetable> implements TimetableSchema {
  TimetableOnline() : super(documentReference: doc, fromJson: Timetable.fromJson);

  static DocumentReference<Json> doc() => FirebaseFirestore.instance
      .collection("timetable")
      .doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  Future<void> copyTo(covariant TimetableSchema to) async {
    await super.copyTo(to);
    await entries.copyTo(to.entries);
  }

  @override
  Collection<Document<TimetableEntry>, TimetableEntry> get entries =>
      OnlineCollection<OnlineDocument<TimetableEntry>, TimetableEntry>(
        collection: () => document.collection("entries"),
        buildType: (doc) => OnlineDocument<TimetableEntry>(
          documentReference: () => doc,
          fromJson: TimetableEntry.fromJson,
        ),
      );
}

class TimetableOffline extends OfflineDocument<Timetable> implements TimetableSchema {
  TimetableOffline() : super(key: "timetable", fromJson: Timetable.fromJson);

  @override
  Collection<Document<TimetableEntry>, TimetableEntry> get entries =>
      OfflineCollection<OfflineDocument<TimetableEntry>, TimetableEntry>(
        parent: this,
        collection: "entries",
        buildType: (id) => OfflineDocument(
          key: id,
          fromJson: TimetableEntry.fromJson,
        ),
      );
}

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

  factory TimetableEntry.fromJson(Json json) => TimetableEntry(
        day: json["day"],
        lesson: json["lesson"],
        teacher: json["teacher"],
        className: json["className"],
        room: json["room"],
        subjectId: json["subjectId"],
      );

  Json toJson() => {
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
