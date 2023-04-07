/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

abstract class Document<T> extends ChangeNotifier {
  Timer? _currentFlush;

  /// Currently loaded data. Null if it has not been loaded yet.
  T? data;

  /// Returns the id of the document.
  String get id;

  /// Loads data from the document and sets it to [data].
  /// If data was already loaded, [data] is returned.
  /// If data was already loaded and [forceRefresh] is true the data will be refreshed.
  Future<T> load([bool forceRefresh = false]);

  void flushDelayed([Duration? delay = const Duration(seconds: 10)]) {
    if (_currentFlush != null) _currentFlush!.cancel();
    _currentFlush = Timer(delay!, () async {
      await flush();
      _currentFlush = null;
    });
  }

  /// Writes [data] to database.
  /// Requires data to be loaded before.
  Future<void> flush();

  /// Deletes the current document in the database.
  /// Does not require a load before.
  Future<void> delete();

  /// Returns a stream which will contain snapshots of the current data, if it is modified.
  /// If the document is deleted, the stream will return null and will probably close.
  Stream<T?> snapshots();

  /// Copies the data of the current document to the given one. It also automatically flushes the
  /// given document after setting the data to write the changes to the database of the given
  /// document.
  /// This function should be overridden if there are properties outside of [T] because these are
  /// not copied in this function. The override function must also call super to copy the data.
  @mustCallSuper
  Future<void> copyTo(Document<T> to) async => to
    ..data = await load()
    ..flush();

  @override
  String toString() {
    return 'Document{id: $id, data: $data}';
  }

  @override
  bool operator ==(Object other) {
    return other is Document && other.id == id;
  }

  @override
  int get hashCode => super.hashCode ^ id.hashCode;
}

class StreamConsumer<T> extends StatelessWidget {
  const StreamConsumer({
    Key? key,
    required this.doc,
    required this.builder,
    this.errorBuilder,
  }) : super(key: key);

  final Document<T> doc;
  final Widget Function(BuildContext context, Document<T> doc, T t) builder;
  final Widget? Function(BuildContext context, Document<T> doc, Object? error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    doc.load();

    return StreamBuilder<T?>(
      initialData: doc.data,
      stream: doc.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return builder.call(context, doc, snapshot.data as T);

        return errorBuilder?.call(context, doc, snapshot.error) ?? Container();
      },
    );
  }
}

class StreamSelector<T, V> extends StatelessWidget {
  const StreamSelector({
    Key? key,
    required this.doc,
    required this.selector,
    required this.builder,
    this.errorBuilder,
  }) : super(key: key);

  final Document<T> doc;
  final Widget Function(BuildContext context, Document doc, T t, V v) builder;
  final V Function(T t) selector;
  final Widget? Function(BuildContext context, Document doc, Object? error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    doc.load();
    V? v;
    late Widget currentBuild;

    return StreamConsumer<T>(
      doc: doc,
      errorBuilder: errorBuilder,
      builder: (context, doc, t) {
        if (v == null) {
          v = selector.call(t);
        } else {
          V newV = selector.call(t);
          if (v == newV) return currentBuild;

          v = newV;
        }

        currentBuild = builder.call(context, doc, t, v as V);
        return currentBuild;
      },
    );
  }
}

abstract class Collection<D extends Document<T>, T> {
  /// Returns a list of all documents that are in this collection.
  Future<List<D>> get items;

  /// Return the document [D] of this collection associated with the given [id].
  D operator [](String id);

  /// Creates a document in the the collection with the given data.
  /// Returned document is already loaded.
  Future<D> add(T data);

  /// Returns a stream of snapshots of the current state of the collection.
  /// The returned list contains documents which are by default already loaded.
  /// Stream will fire if docs are deleted or added, not if they are modified.
  Stream<List<D>> snapshots([bool loadDocs = true]);

  /// Returns the raw data of all docs in this collection.
  Future<List<T>> get loadedItems async => (await items).asyncMap((t) => t.load());

  /// Deletes all documents in this collection.
  Future<void> deleteAll() async {
    for (var element in await items) {
      element.delete();
    }
  }

  /// Copies all documents in this collection to another collection.
  @nonVirtual
  Future<void> copyTo(Collection<D, T> to) async {
    for (var value in (await loadedItems)) {
      to.add(value);
    }
  }
}

class OnlineDocument<T> extends Document<T> {
  final DocumentReference<Map<String, dynamic>> Function() documentReference;
  final T Function(Map<String, dynamic> data) fromJson;

  OnlineDocument({required this.documentReference, required this.fromJson});

  @override
  String get id => document.id;

  @nonVirtual
  @protected
  DocumentReference<T> get document => documentReference.call().withConverter(
        fromFirestore: (snapshot, options) => fromJson.call(snapshot.data()!),
        toFirestore: (value, options) => (value as dynamic).toJson(),
      );

  @override
  Future<T> load([bool forceRefresh = false]) async {
    innerLoad() async => (await document.get()).data() as T;
    if (forceRefresh) return data = await innerLoad();

    return data ??= await innerLoad();
  }

  @override
  Future<void> flush() => document.set(data as T, SetOptions(merge: true));

  @override
  Future<void> delete() {
    data = null;

    return document.delete();
  }

  @override
  Stream<T?> snapshots() => document.snapshots().map((event) {
        if (!event.exists) return null;

        return data = event.data() as T;
      });
}

class OfflineDocument<T> extends Document<T> {
  final OfflineCollection? parent;
  final String key;
  final T Function(Map<String, dynamic> data) fromJson;
  Box? _box;

  OfflineDocument({required this.key, required this.fromJson, this.parent});

  @override
  String get id => key;

  @override
  Future<T> load([bool forceRefresh = false]) async {
    _box ??= await Hive.openBox(key);

    fromBox() async => fromJson.call(_box!.toMap().map((k, v) => MapEntry(k.toString(), v)));
    if (forceRefresh) return data = await fromBox();

    return data ??= await fromBox();
  }

  @override
  Future<void> flush() => _box!.putAll((data as dynamic).toJson());

  @override
  Future<void> delete() async {
    data = null;
    if (parent != null) parent!.keys = parent!.keys..remove(key);

    return Hive.deleteBoxFromDisk(key);
  }

  @override
  Stream<T?> snapshots() {
    var controller = StreamController<T?>.broadcast();

    load().then((firstData) {
      controller.add(firstData);

      _box!.watch().listen((event) async {
        //TODO fires on every key updated!
        if (event.deleted) {
          controller.add(null);
          controller.close();
        } else {
          controller.add((data = await load(true))!);
        }
      });
    });

    return controller.stream;
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
  Future<D> add(T data) async {
    var doc = await collection.call().add((data as dynamic).toJson());

    return buildType.call(doc)..load();
  }

  @override
  D operator [](String id) => buildType(collection.call().doc(id));

  @override
  Stream<List<D>> snapshots([loadDocs = true]) {
    return collection.call().snapshots().asyncMap((event) => event.docs.asyncMap((snap) async {
          var doc = buildType.call(snap.reference);
          if (loadDocs) await doc.load(true);

          return doc;
        }));
  }
}

class OfflineCollection<D extends OfflineDocument<T>, T> extends Collection<D, T> {
  final OfflineDocument parent;
  final String collection;
  final D Function(String id, OfflineCollection<D, T> parent) buildType;

  OfflineCollection({required this.parent, required this.collection, required this.buildType});

  List<String> get keys => (parent._box!.get(collection, defaultValue: []) as List).cast<String>();

  set keys(List<String> keys) => parent._box!.put(collection, keys);

  @override
  Future<List<D>> get items async {
    await parent.load();

    return keys.map((key) => buildType.call(key, this)).toList();
  }

  @override
  D operator [](String id) => buildType.call(id, this);

  @override
  Future<D> add(T data) async {
    await parent.load();
    var doc = buildType.call(StringUtils.randomAlphaNumeric(20), this);

    doc._box ??= await Hive.openBox(doc.key);
    doc.data = data;
    await doc.flush();

    keys = keys..add(doc.id);

    return doc;
  }

  @override
  Future<void> deleteAll() async {
    await super.deleteAll();
    keys = [];
  }

  @override
  Stream<List<D>> snapshots([loadDocs = true]) {
    var controller = StreamController<List<D>>.broadcast();

    parent.load().then((loaded) async {
      parent._box!.watch(key: collection).listen((event) async {
        if (event.deleted) {
          controller.close();
        } else {
          var items = await this.items;
          if (loadDocs) await Future.wait(items.map((e) => e.load()));

          controller.add(items);
        }
      });

      var items = await this.items;
      if (loadDocs) await Future.wait(items.map((e) => e.load()));

      controller.add(items);
    });

    return controller.stream;
  }
}
