/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/type_definitions.dart';

class Timetable {
  bool shared;

  Timetable({
    this.shared = false,
  });

  static TimetableSchema get([bool online = storeOnline]) =>
      online ? TimetableOnline() : TimetableOffline();

  Json toJson() => {
        "shared": shared,
      };

  factory Timetable.fromJson(Json json) => Timetable(
        shared: json["shared"] ?? false,
      );
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
        buildType: (id, parent) => OfflineDocument(
          parent: parent,
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
  Document<Subject>? subject;

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
        subject: json["subject"] != null ? Subjects.get().entries[json["subject"]] : null,
      );

  Json toJson() => {
        "day": day,
        "lesson": lesson,
        "teacher": teacher,
        "className": className,
        "room": room,
        "subject": subject?.id,
      };

  bool equalData(TimetableEntry? other) =>
      other != null &&
      other.teacher == teacher &&
      other.className == className &&
      other.room == room &&
      other.subject == subject;

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
