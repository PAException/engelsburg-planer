/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
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

abstract class DataSupplier<T> {
  T get online;

  T get offline;

  void delete();

  void convert(T to, T from);
}

abstract class DataFolder<T extends DataSupplier<T>> {
  T? operator [](String id);

  void operator []=(String id, T data);

  Future<List<T>> get items;

  void deleteAll() async {
    for (var element in await items) {
      element.delete();
    }
  }
}

abstract class Timetable extends DataSupplier<Timetable> {
  @override
  Timetable get offline => TimetableOnlineImpl(); //TODO

  @override
  Timetable get online => TimetableOnlineImpl();

  @override
  void convert(Timetable to, Timetable from) {}

  Future<bool> get shared;

  DataFolder<TimetableEntry> get entries;
}

class TimetableOnlineImpl extends Timetable {
  Timetable? timetable;

  @override
  void delete() {
    FirebaseFirestore.instance.doc("timetable").delete();
  }

  @override
  DataFolder<TimetableEntry> get entries => TimetableEntriesOnline();

  @override
  Future<bool> get shared async {
    var a = await FirebaseFirestore.instance.doc("timetable").get();

    return a.data()?["shared"] ?? false;
  }
}

class TimetableEntriesOnline extends DataFolder<TimetableEntry> {
  @override
  TimetableEntry operator [](String id) => TimetableEntryOnlineImpl(id);

  @override
  void operator []=(String id, TimetableEntry data) {
    FirebaseFirestore.instance.doc("timetable").collection("entries").add(data.toMap());
  }

  @override
  Future<List<TimetableEntry>> get items async {
    var a = await FirebaseFirestore.instance.doc("timetable").collection("entries").get();
    var entries = Map.fromEntries(a.docs.map((e) => MapEntry(e.id, e.data() as TimetableEntry)));

    return entries.values.toList();
  }
}

abstract class TimetableEntry extends DataSupplier<TimetableEntry> {
  final String id;

  Map<String, dynamic> toMap() {
    return {};
  }

  TimetableEntry(this.id);

  @override
  TimetableEntry get offline => TimetableEntryOnlineImpl(id); //TODO
  @override
  TimetableEntry get online => TimetableEntryOnlineImpl(id);

  @override
  void convert(TimetableEntry to, TimetableEntry from) {}

  @override
  void delete() {}
}

class TimetableEntryOnlineImpl extends TimetableEntry {
  TimetableEntryOnlineImpl(super.id);
}
