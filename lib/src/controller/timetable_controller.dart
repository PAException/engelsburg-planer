/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/models/api/timetable.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class TimetableService extends DataService {
  Future<List<TimetableEntry>> get timetable async => await Timetable.online.entries.loadedItems;

  void _addEntry(TimetableEntry entry) => Timetable.online.entries.add(entry);

  Future<TimetableEntry> getEntry(int day, int lesson) async => (await timetable).firstWhere(
        (entry) => entry.day == day && entry.lesson == lesson,
        orElse: () => TimetableEntry(day: day, lesson: lesson),
      );

  void _removeEntry(int day, int lesson) async {
    var docs = await Timetable.online.entries.items;
    var i = (await timetable).indexWhere((entry) => entry.day == day && entry.lesson == lesson);

    if (i != -1) docs[i].delete();
  }

  @override
  Future<void> setup() async {}

  Future<TimetableEntry?> updateTimetable({
    required int day,
    required int lesson,
    int? subjectId,
    String? teacher,
    String? className,
    String? room,
  }) async {
    print("Updating");
    if (subjectId == null) {
      _removeEntry(day, lesson);
      //return null;
    }

    final entry = await getEntry(day, lesson);
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
    print("Updating2");
    print(entry);
    _addEntry(entry);

    return entry;
  }

  Future<List<TimetableEntry>> getTimetable(DateTime? dateTime) async {
    if (dateTime == null) return timetable;

    return (await timetable).where((entry) => entry.day == dateTime.weekday).toList();
  }
}

abstract class Document<T> {
  T? _data;

  Future<T> load([bool forceRefresh = false]); //Get
  Future<void> flush(); //Update
  Future<void> delete(); //Delete

  Stream<T> get snapshots;

  String get id;

  @nonVirtual
  void set(T data) => this._data = data;

  @mustCallSuper
  Future<void> copyTo(Document<T> to) async => to
    ..set(await load())
    ..flush();
}

class OnlineDocument<T> extends Document<T> {
  final DocumentReference<Map<String, dynamic>> Function() documentReference;
  final T Function(Map<String, dynamic> data) fromJson;

  OnlineDocument({
    required this.documentReference,
    required this.fromJson,
  });

  @nonVirtual
  DocumentReference<T> get document => documentReference.call().withConverter(
        fromFirestore: (snapshot, options) => fromJson.call(snapshot.data()!),
        toFirestore: (value, options) => (value as dynamic).toJson(),
      );

  @override
  Future<T> load([bool forceRefresh = false]) async {
    load() async => (await document.get()).data() as T;
    if (forceRefresh) return _data = await load();

    return _data ?? await load();
  }

  @override
  Future<void> delete() {
    _data = null;

    return document.delete();
  }

  @override
  Future<void> flush() => document.set((_data as dynamic).toJson(), SetOptions(merge: true));

  @override
  Stream<T> get snapshots => document.snapshots().map((event) => event.data()!);

  @override
  String get id => document.id;
}

class OfflineDocument<T> extends Document<T> {
  final String key;
  final T Function(Map<String, dynamic> data) fromJson;

  OfflineDocument({required this.key, required this.fromJson});

  Future<Box> get box => Hive.openBox(key);

  @override
  Future<void> delete() async {
    _data = null;
    if (!Hive.isBoxOpen(key)) return Hive.deleteBoxFromDisk(key);

    return (await box).deleteFromDisk();
  }

  @override
  Future<void> flush() async {
    return (await box).putAll((_data as dynamic).toJson());
  }

  @override
  Future<T> load([bool forceRefresh = false]) async {
    fromBox() async => fromJson.call((await box).toMap() as Map<String, dynamic>);
    if (forceRefresh) return _data = await fromBox();

    return _data ?? await fromBox();
  }

  @override
  Stream<T> get snapshots {
    var controller = StreamController<T>.broadcast();
    box.then((box) => box.watch().listen((event) async {
          if (event.deleted) {
            controller.close();
          } else {
            controller.add(await load(true));
          }
        }));

    return controller.stream;
  }

  @override
  String get id => key;
}

abstract class Collection<D extends Document<T>, T> {
  D operator [](String id);

  void add(T data);

  Future<List<D>> get items;

  Stream<Map<String, T>> get snapshots;

  @nonVirtual
  D get(String id) => this[id];

  Future<List<T>> get loadedItems async => (await items).asyncMap((t) => t.load());

  void deleteAll() async {
    for (var element in await items) {
      element.delete();
    }
  }

  Future<void> copyTo(Collection<D, T> to) async {
    for (var value in (await loadedItems)) {
      to.add(value);
    }
  }
}

class OnlineCollection<D extends OnlineDocument<T>, T> extends Collection<D, T> {
  final CollectionReference<Map<String, dynamic>> Function() collection;
  final D Function(DocumentReference<Map<String, dynamic>> doc) buildType;

  OnlineCollection({required this.collection, required this.buildType});

  @override
  Future<List<D>> get items async {
    var res = await collection.call().get();

    return res.docs.map((e) => buildType(e.reference)).toList();
  }

  @override
  void add(T data) => collection.call().add((data as dynamic).toJson());

  @override
  D operator [](String id) => buildType(collection.call().doc(id));

  @override
  Stream<Map<String, T>> get snapshots => collection.call().snapshots().asyncMap((event) async {
        Map<String, T> map = {};

        for (var doc in event.docs) {
          map[doc.id] = await buildType.call(doc.reference).load();
        }
        return map;
      });
}

class OfflineCollection<D extends OfflineDocument<T>, T> extends Collection<D, T> {
  final OfflineDocument parent;
  final String collection;
  final D Function(String id) buildType;

  OfflineCollection({required this.parent, required this.collection, required this.buildType});

  @override
  D operator [](String id) => buildType.call(id);

  @override
  void add(T data) async {
    var doc = buildType.call(StringUtils.randomAlphaNumeric(10));

    await doc.load();
    doc.set(data);
  }

  @override
  Future<List<D>> get items async {
    var keys = (await parent.box).get(collection, defaultValue: []) as List<String>;

    return keys.map((e) => buildType.call(e)).toList();
  }

  @override
  Stream<Map<String, T>> get snapshots {
    var controller = StreamController<Map<String, T>>.broadcast();
    parent.box.then((box) => box.watch(key: collection).listen((event) async {
          if (event.deleted) {
            controller.close();
          } else {
            Map<String, T> map = {};
            for (var doc in (await this.items)) {
              map[doc.id] = await doc.load(true);
            }

            controller.add(map);
          }
        }));

    return controller.stream;
  }
}

/*
abstract class DataSupplier<T> {
  T get online;

  T get offline;
}

mixin DataDefinition<T> {
  void convert(T to, T from);

//Future<Map<String, dynamic>> toMap();

//Future<T> fromMap(Map<String, dynamic> map);
}

abstract class DataEntry<T> {
  Future<void> delete();
}

abstract class OnlineDataEntry<T> extends DataEntry<T> {
  DocumentReference<Map<String, dynamic>> get document;

  @override
  Future<void> delete() => document.delete();
}

abstract class DataFolder<T extends DataEntry<T>> {
  T? operator [](String id);

  void operator []=(String id, T data);

  Future<List<T>> get items;

  void deleteAll() async {
    for (var element in await items) {
      element.delete();
    }
  }
}

abstract class OnlineDataFolder<T extends DataEntry<T>> extends DataFolder<T> {}

abstract class Timetable with DataSupplier<Timetable>, DataDefinition<Timetable> {
  @override
  Timetable get offline => TimetableOnlineImpl(); //TODO

  @override
  Timetable get online => TimetableOnlineImpl();

  @override
  void convert(Timetable to, Timetable from) {}

  Future<bool> get shared;

  DataFolder<TimetableEntry> get entries;
}

class TimetableOnlineImpl extends OnlineDataEntry<Timetable> implements Timetable {
  Timetable? timetable;

  @override
  DocumentReference<Map<String, dynamic>> get document =>
      FirebaseFirestore.instance.doc("timetable");

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

abstract class TimetableEntry extends DataEntry<TimetableEntry> {
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
*/
