/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';

typedef Parser<T> = T Function(DocumentData data);
typedef DocumentData = Map<String, dynamic>;
typedef CollectionData<T> = Map<DocumentReference<T>, DocumentData>;

class Grades {
  Grades({
    required this.usePoints,
    required this.roundEachType,
  });

  bool usePoints; // Default if className starts not with number
  bool roundEachType; // Default false

  static DocumentReference<Grades> ref() =>
      const DocumentReference<Grades>("grades", Grades.fromJson);

  static CollectionReference<Grade> entries() => ref().collection<Grade>("entries", Grade.fromJson);

  factory Grades.fromJson(Map<String, dynamic> json) => Grades(
        usePoints: json["usePoints"] ?? false,
        roundEachType: json["roundEachType"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "usePoints": usePoints,
        "roundEachType": roundEachType,
      };
}

/// Object that refers to something with a blueprint how to build it.
@immutable
class Reference<T> {
  final String path;
  final Parser<T> parser;

  const Reference(this.path, this.parser);
}

/// Same as Reference<T>, but only to documents.
@immutable
class DocumentReference<T> extends Reference<T> {
  const DocumentReference(super.path, super.parser);

  CollectionReference<D> collection<D>(String name, Parser<D> parser) =>
      CollectionReference<D>("$path/$name", parser);

  @nonVirtual
  Document<T> storage([bool? online]) => Document<T>(Storage.impl(online), this);
}

/// Same as Reference<T>, but only to collections.
/// The parser only refers to the documents within that collection.
@immutable
class CollectionReference<T> extends Reference<T> {
  const CollectionReference(super.path, super.parser);

  DocumentReference<T> doc(String name) => DocumentReference<T>("$path/$name", parser);

  @nonVirtual
  Collection<T> storage([bool? online]) => Collection<T>(Storage.impl(online), this);
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Document<T> extends DocumentReference<T> {
  final Storage _storage;

  Document(this._storage, DocumentReference<T> ref) : super(ref.path, ref.parser);

  @override
  Collection<D> collection<D>(String name, Parser<D> parser) =>
      Collection<D>(_storage, super.collection(name, parser));

  Future<T> load() => _storage.safeData(this);

  T? get data => _storage.data(this);

  Future<void> delete() => _storage.deleteDocument(this);

  Stream<T?> snapshots() => _storage.snapshotsOfDocument<T>(this);
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Collection<T> extends CollectionReference<T> {
  final Storage _storage;

  Collection(this._storage, CollectionReference<T> ref) : super(ref.path, ref.parser);

  @override
  Document<T> doc(String name) => Document<T>(_storage, super.doc(name));

  Future<List<Document<T>>> documents() => _storage.documentsOfCollection(this);

  Future<void> clear() => _storage.clearCollection(this);

  Stream<List<Document<T>>> snapshots() => _storage.snapshotsOfCollection(this);
}

abstract class Storage {
  static final Storage _online = OnlineStorage();
  static final Storage _offline = OnlineStorage(); //TODO

  /// Get implementation of storage
  static Storage impl([bool? online]) => online ?? false ? _online : _offline;

  /// Caches present data (reference, json)
  ///
  /// !!! There is no guarantee that this is the latest data !!!
  ///     -> only if document has also an active snapshot stream
  final Map<String, DocumentData> _data = {};

  /// Caches snapshot streams of documents (reference, stream)
  final Map<String, Stream<dynamic>> _documentSnapshots = {};

  /// Caches snapshot streams of collections (reference, stream)
  final Map<String, Stream<dynamic>> _collectionSnapshots = {};

  /// Get data if already loaded
  @nonVirtual
  T? data<T>(Document<dynamic> doc) {
    var data = _data[doc.path];
    if (data == null) return null;

    return doc.parser.call(data);
  }

  /// Get data, if not loaded await load
  @nonVirtual
  Future<T> safeData<T>(Document<dynamic> doc) async {
    return data<T>(doc) ?? doc.parser.call(_data[doc.path] = await _loadDocument(doc));
  }

  /// Reloads document, loads if not already loaded
  @nonVirtual
  Future<void> loadDocument(DocumentReference<dynamic> doc) async {
    if (_documentSnapshots.containsKey(doc.path)) return;

    _data[doc.path] = await _loadDocument(doc);
  }

  /// Creates a new document within a collection.
  @nonVirtual
  Future<String> addDocument(CollectionReference<dynamic> collection, dynamic data) {
    var id = StringUtils.randomAlphaNumeric(20);

    return setDocument(collection.doc(id), data).then((value) => id);
  }

  /// Sets data of a document in the storage.
  /// [data] needs to have a [toJson] function.
  /// Returns future with the result of the creation of the document.
  @nonVirtual
  Future<bool> setDocument(DocumentReference<dynamic> doc, dynamic data) async {
    try {
      DocumentData json = data.toJson();

      return _setDocument(doc, json).whenComplete(() => _data[doc.path] = json);
    } on NoSuchMethodError {
      debugPrint("Document cannot be created, data cannot be parsed into json.");
      return false;
    } catch (e) {
      debugPrint("Document cannot be created, unknown error.");
      return false;
    }
  }

  /// Deletes a document, removes the data from the the cache and closes the snapshot stream.
  @nonVirtual
  Future<bool> deleteDocument(DocumentReference<dynamic> doc) => _deleteDocument(doc).then((value) {
        _data.remove(doc.path);

        return value;
      });

  /// Get all documents of a collection.
  @nonVirtual
  Future<List<Document<T>>> documentsOfCollection<T>(Collection<T> collection) async {
    return (await _documentsOfCollection(collection)).mapToList((ref, value) {
      _data[ref.path] = value;

      return Document<T>(this, ref);
    });
  }

  /// Deletes all documents within a collection.
  @nonVirtual
  Future<void> clearCollection(Collection<dynamic> collection) async {
    var docs = await documentsOfCollection(collection);

    await Future.wait(docs.map((doc) => deleteDocument(doc)));
  }

  /// Get a stream of snapshots of the document.
  /// If the document is deleted the stream is closed, otherwise the latest version of the document
  /// will be added to the stream.
  @nonVirtual
  Stream<T> snapshotsOfDocument<T>(Document<T> doc) {
    //Check for existing snapshot stream to return
    if (_documentSnapshots.containsKey(doc.path)) {
      return _documentSnapshots[doc.path]!.cast<T>();
    }

    //Create new stream, if canceled remove from list
    var controller = StreamController<T?>.broadcast(
      onCancel: () {
        _documentSnapshots[doc.path]?.close();
        _documentSnapshots.remove(doc.path);
      },
    );

    return (_documentSnapshots[doc.path] =
            _snapshotsOfDocument(doc).map((newDoc) => doc.parser(newDoc)))
        .ca;

    //Listen to the stream of the implementation
    _snapshotsOfDocument(doc).listen((event) {
      if (event == null) {
        //on null close stream and remove data, the document was deleted
        _data.remove(doc.path);
        controller.close();
        _documentSnapshots.remove(doc.path);
      } else {
        //add new snapshot to stream and update data
        _data[doc.path] = event;
        controller.add(doc.parser.call(event));
      }
    });

    return (_documentSnapshots[doc.path] = controller).stream;
  }

  /// Get a stream of snapshots of the collection.
  @nonVirtual
  Stream<List<Document<T>>> snapshotsOfCollection<T>(Collection<T> collection) {
    //Check for existing snapshot stream to return
    var controller = _collectionSnapshots[collection.path];
    if (controller != null) {
      return controller.stream.cast<List>().map((e) => e.cast<Document<T>>());
    }

    //Create new stream, if canceled remove from list
    var newController = StreamController<List<Document<T>>>.broadcast(
      onCancel: () => _collectionSnapshots.remove(collection.path),
    );

    //Listen to the stream of the implementation
    _snapshotsOfCollection(collection).listen((event) {
      //add new snapshot of collection to stream and update data
      newController.add(event.mapToList((ref, value) {
        _data[ref.path] = value;

        return Document<T>(this, ref);
      }));
    });

    return newController.stream;
  }

  /// Set the data of a document.
  /// Creates new document if not existing.
  Future<bool> _setDocument(DocumentReference<dynamic> doc, DocumentData data);

  /// Get the data of the document.
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc);

  /// Delete a document by reference.
  /// Returns if the removal succeeded (document is not existing is also true).
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc);

  /// Return the stream of the snapshots of the document.
  /// If the stream object is null the document will be marked as removed.
  Stream<DocumentData> _snapshotsOfDocument(DocumentReference<dynamic> doc);

  /// Return all documents of a collection.
  Future<CollectionData<T>> _documentsOfCollection<T>(Collection<T> collection);

  /// Return the stream of the snapshots of the collection.
  Stream<CollectionData<T>> _snapshotsOfCollection<T>(Collection<T> collection);
}

class OnlineStorage extends Storage {
  static FirebaseFirestore instance = FirebaseFirestore.instance;

  @override
  Future<bool> _setDocument(DocumentReference<dynamic> doc, Map<String, dynamic> data) =>
      evaluate(() => instance.doc(doc.path).set(data));

  @override
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc) =>
      instance.doc(doc.path).get().then((value) => value.data() ?? {});

  @override
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc) =>
      evaluate(() => instance.doc(doc.path).delete());

  @override
  Stream<DocumentData> _snapshotsOfDocument(DocumentReference<dynamic> doc) {
    var controller = StreamController<DocumentData>.broadcast();

    var subscription = instance.doc(doc.path).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        controller.add(doc.data()!);
      } else {
        controller.close();
      }
    });

    return controller.stream..listen(null, onDone: () => subscription.cancel());
  }

  @override
  Future<CollectionData<T>> _documentsOfCollection<T>(Collection<T> collection) async {
    var snapshot = await instance.collection(collection.path).get();

    return snapshot.docs.toMap(
      key: (doc) => DocumentReference<T>(doc.reference.path, collection.parser),
      value: (doc) => doc.data(),
    );
  }

  @override
  Stream<CollectionData<T>> _snapshotsOfCollection<T>(Collection<T> collection) {
    var snapshots = instance.collection(collection.path).snapshots();

    return snapshots.map((snapshot) {
      return snapshot.docs.toMap(
        key: (doc) => DocumentReference(doc.reference.path, collection.parser),
        value: (doc) => doc.data(),
      );
    });
  }
}

/// Return false on error, otherwise true
Future<bool> evaluate(FutureOr Function() toEvaluate) async {
  try {
    await Future.value(toEvaluate.call());

    return true;
  } catch (_) {
    return false;
  }
}
