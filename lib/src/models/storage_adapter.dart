/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/models/local_storage.dart';
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

  static CollectionReference<Grade> entries() =>
      ref().collection<Grade>("entries", Grade.fromJson);

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
abstract class Reference<T> {
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
  Document<T> storage(Storage storage) => Document<T>.ref(storage, this);
}

/// Same as Reference<T>, but only to collections.
/// The parser only refers to the documents within that collection.
@immutable
class CollectionReference<T> extends Reference<T> {
  const CollectionReference(super.path, super.parser);

  DocumentReference<T> doc(String name) =>
      DocumentReference<T>("$path/$name", parser);

  @nonVirtual
  Collection<T> storage(Storage storage) => Collection<T>.ref(storage, this);
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Document<T> extends DocumentReference<T> {
  final Storage _storage;

  Document.ref(this._storage, DocumentReference<T> ref)
      : super(ref.path, ref.parser);

  const Document(this._storage, String path, Parser<T> parser)
      : super(path, parser);

  @override
  Collection<D> collection<D>(String name, Parser<D> parser) =>
      Collection<D>.ref(_storage, super.collection(name, parser));

  Future<T> load() => _storage.safeData(this);

  T? get data => _storage.data(this);

  Future<bool> set(T data) => _storage.setDocument(this, data);

  void setDelayed(
    T data, {
    bool updateStreams = true,
    Duration delay = const Duration(seconds: 10),
  }) =>
      _storage.setDocumentDelayed(
        this,
        data,
        delay: delay,
        updateStreams: updateStreams,
      );

  Future<void> delete() => _storage.deleteDocument(this);

  Stream<T?> stream() => _storage.documentStream<T>(this);

  Future<bool> copyTo(Storage target) async =>
      target.setDocument(this, await load());
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Collection<T> extends CollectionReference<T> {
  final Storage _storage;

  Collection.ref(this._storage, CollectionReference<T> ref)
      : super(ref.path, ref.parser);

  const Collection(this._storage, String path, Parser<T> parser)
      : super(path, parser);

  @override
  Document<T> doc(String name) => Document<T>.ref(_storage, super.doc(name));

  Future<List<Document<T>>> documents() => _storage.getCollection(this);

  Future<String> addDocument(T data) => _storage.addDocument(this, data);

  Future<void> clear() => _storage.clearCollection(this);

  Stream<List<Document<T>>> stream() => _storage.collectionStream(this);

  Future<List<bool>> copyTo(Storage target) async {
    var docs = await documents();

    return docs.asyncMap((doc) => target.setDocument(doc, doc.data!));
  }
}

abstract class Storage {
  static final Storage online = FirestoreStorageImpl();
  static final Storage offline = LocalStorageImpl();

  /// Copies all provided references from one storage to another
  static Future<void> copyAll({
    required Storage from,
    required Storage to,
    required List<Reference> refs,
  }) async {
    await refs.asyncMap((ref) async {
      if (ref is DocumentReference) {
        return Document.ref(from, ref).copyTo(to);
      } else if (ref is CollectionReference) {
        return Collection.ref(from, ref).copyTo(to);
      }
    });
  }

  /// Caches present data (reference, json)
  ///
  /// !!! There is no guarantee that this is the latest data !!!
  ///     -> only if document has also an active snapshot stream
  final Map<String, DocumentData> _data = {};

  /// Caches snapshot streams of documents (reference, stream)
  final Map<String, StreamController<dynamic>> _documentStreamController = {};
  final Map<String, StreamSubscription<dynamic>> _documentStreams = {};

  /// Caches snapshot streams of collections (reference, stream)
  final Map<String, StreamController<dynamic>> _collectionStreamController = {};
  final Map<String, StreamSubscription<dynamic>> _collectionStreams = {};

  /// Caches timers for delayed document updates (reference, timer)
  final Map<String, Timer> _delayedDocumentUpdates = {};

  /// Get data if already loaded
  @nonVirtual
  T? data<T>(Document<dynamic> doc) {
    var data = _data[doc.path];
    if (data == null) return null;

    return doc.parser.call(data);
  }

  /// Get data, if not loaded await load
  @nonVirtual
  Future<T> safeData<T>(Document<dynamic> doc) async =>
      data<T>(doc) ??
      doc.parser.call(_data[doc.path] = await _loadDocument(doc));

  /// Creates a new document within a collection.
  @nonVirtual
  Future<String> addDocument(CollectionReference collection, dynamic data) {
    var id = StringUtils.randomAlphaNumeric(20);

    return setDocument(collection.doc(id), data).then((value) => id);
  }

  /// Sets data of a document in the storage.
  /// [data] needs to have a [toJson] function.
  /// Returns future with the result of the creation of the document.
  @nonVirtual
  Future<bool> setDocument<T>(DocumentReference<T> doc, T data) async {
    try {
      DocumentData json = (data as dynamic).toJson();

      return _setDocument(doc, json).whenComplete(() => _data[doc.path] = json);
    } on NoSuchMethodError {
      debugPrint("Document cannot be set, data cannot be parsed into json.");
      return false;
    } catch (e) {
      debugPrint("Document cannot be set, unknown error.");
      return false;
    }
  }

  /// Sets the actual document after a given delay.
  /// If not disabled the streams will send an update, though the document is
  /// not actually updated yet.
  /// If the update of the document fails the stream will be added docs,
  /// as if the changes were reverted.
  void setDocumentDelayed<T>(
    DocumentReference<T> doc,
    T data, {
    bool updateStreams = true,
    Duration delay = const Duration(seconds: 10),
  }) {
    String key = doc.path;

    //Cancel any active timer for this document
    _delayedDocumentUpdates[key]?.cancel();

    //Set timer that sets data after delay
    _delayedDocumentUpdates[key] = Timer(delay, () async {
      var result = await setDocument(doc, data);
      _delayedDocumentUpdates.remove(key);

      //If update fails update stream
      if (!result) {
        //Parse parent collection of document
        var collectionPath = key.substring(0, key.lastIndexOf("/"));
        var collection = Collection<T>(this, collectionPath, doc.parser);

        //Get current documents and add to stream
        var collectionController = _collectionStreamController[key];
        if (collectionController != null) {
          getCollection(collection)
              .then((docs) => collectionController.add(docs));
        }
      }
    });

    if (!updateStreams) return;

    //If document has stream add updated data
    var documentController = _documentStreamController[key];
    if (documentController != null) documentController.add(data);

    var collectionController = _collectionStreamController[key];
    if (collectionController != null) {
      try {
        //Data will only be written to cache, no information will be added to stream
        _data[key] = (data as dynamic).toJson();
      } on NoSuchMethodError {
        debugPrint("Document cannot be set, data cannot be parsed into json.");
      }

      //Parse parent collection of document
      var collectionPath = key.substring(0, key.lastIndexOf("/"));
      var collection = Collection<T>(this, collectionPath, doc.parser);

      //Get current documents and add to stream
      getCollection(collection).then((docs) => collectionController.add(docs));
    }
  }

  /// Deletes a document, removes the data from the the cache and closes the snapshot stream.
  @nonVirtual
  Future<bool> deleteDocument(DocumentReference<dynamic> doc) =>
      _deleteDocument(doc).then((value) {
        _data.remove(doc.path);

        return value;
      });

  /// Get all documents of a collection.
  @nonVirtual
  Future<List<Document<T>>> getCollection<T>(Collection<T> collection) async {
    return (await _getCollection(collection)).mapToList((ref, value) {
      _data[ref.path] = value;

      return Document<T>.ref(this, ref);
    });
  }

  /// Deletes all documents within a collection.
  @nonVirtual
  Future<void> clearCollection(Collection<dynamic> collection) async {
    var docs = await getCollection(collection);

    await Future.wait(docs.map((doc) => deleteDocument(doc)));
  }

  /// Get a stream of snapshots of the document.
  /// If the document is deleted the stream is closed, otherwise the latest version of the document
  /// will be added to the stream.
  ///
  /// !!! -- Document streams should only be used for documents, that cant be queried in a collection -- !!!
  ///
  @nonVirtual
  Stream<T?> documentStream<T>(Document<T> doc) {
    String key = doc.path;

    //Check for existing snapshot stream to return
    var controller = _documentStreamController[key];
    if (controller != null) return controller.stream.cast<T?>();

    //Create new stream, if canceled remove from list
    var newController = StreamController<T?>.broadcast(
      onCancel: () {
        _documentStreamController[key]?.close();
        _documentStreamController.remove(key);
        _documentStreams[key]?.cancel();
        _documentStreams.remove(key);
      },
    );

    //Listen to the stream of the implementation
    _documentStreams[key] = _documentSnapshots(doc).listen((event) {
      if (event == null) {
        //on null close stream and remove data, the document was deleted
        _data.remove(key);
        newController.add(null);
      } else {
        //add new snapshot to stream and update data
        _data[key] = event;
        newController.add(doc.parser.call(event));
      }
    });

    return (_documentStreamController[key] = newController).stream;
  }

  /// Get a stream of snapshots of the collection.
  /// An event is dispatched if a document was created, modified or deleted.
  @nonVirtual
  Stream<List<Document<T>>> collectionStream<T>(Collection<T> collection) {
    String key = collection.path;

    //Check for existing snapshot stream to return
    var controller = _collectionStreamController[key];
    if (controller != null) {
      return controller.stream.cast<List>().map((e) => e.cast<Document<T>>());
    }

    //Create new stream, if canceled close and remove from list
    var newController = StreamController<List<Document<T>>>.broadcast(
      onCancel: () {
        _collectionStreamController[key]?.close();
        _collectionStreamController.remove(key);
        _collectionStreams[key]?.cancel();
        _collectionStreams.remove(key);
      },
    );

    //Listen to the stream of the implementation
    _collectionStreams[key] = _collectionSnapshots(collection).listen((docs) {
      //Add new snapshot of collection to stream and update data
      newController.add(docs.mapToList((ref, value) {
        _data[ref.path] = value;

        return Document<T>.ref(this, ref);
      }));
    });

    //Save controller and return stream
    return (_collectionStreamController[key] = newController).stream;
  }

  /// Set the data of a document.
  /// Creates new document if not existing.
  Future<bool> _setDocument(DocumentReference<dynamic> doc, DocumentData data);

  /// Get the data of the document.
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc);

  /// Delete a document by reference.
  /// Returns true after completion if the document does not exist anymore.
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc);

  /// Return the stream of the snapshots of the document.
  /// Stream only dispatches events if the document is modified.
  /// Else must be handled by stream of the collection.
  Stream<DocumentData?> _documentSnapshots(DocumentReference<dynamic> doc);

  /// Return all documents of a collection.
  Future<CollectionData<T>> _getCollection<T>(Collection<T> collection);

  /// Return the stream of the snapshots of the collection.
  /// Stream must dispatch event if...
  /// - Document is created
  /// - Document is deleted
  /// - Document is modified
  /// ...within the collection
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection);
}

//TODO prefix of path
class FirestoreStorageImpl extends Storage {
  static FirebaseFirestore instance = FirebaseFirestore.instance;

  @override
  Future<bool> _setDocument(
          DocumentReference<dynamic> doc, Map<String, dynamic> data) =>
      evaluate(() => instance.doc(doc.path).set(data));

  @override
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc) =>
      instance.doc(doc.path).get().then((value) => value.data() ?? {});

  @override
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc) =>
      evaluate(() => instance.doc(doc.path).delete());

  @override
  Stream<DocumentData?> _documentSnapshots(DocumentReference<dynamic> doc) =>
      instance.doc(doc.path).snapshots().map((event) => event.data());

  @override
  Future<CollectionData<T>> _getCollection<T>(Collection<T> collection) async {
    var snapshot = await instance.collection(collection.path).get();

    return snapshot.docs.toMap(
      key: (doc) => DocumentReference<T>(doc.reference.path, collection.parser),
      value: (doc) => doc.data(),
    );
  }

  @override
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection) {
    var snapshots = instance.collection(collection.path).snapshots();

    return snapshots.map((snapshot) {
      return snapshot.docs.toMap(
        key: (doc) => DocumentReference(doc.reference.path, collection.parser),
        value: (doc) => doc.data(),
      );
    });
  }
}

class LocalStorageImpl extends Storage {
  static LocalStorage instance = LocalStorage.instance;

  @override
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc) =>
      instance.deleteDocument(doc.path);

  @override
  Future<CollectionData<T>> _getCollection<T>(Collection<T> collection) async {
    var docs = await instance.getCollection(collection.path);

    return docs.toMap(
      key: (doc) => DocumentReference(doc.path, collection.parser),
      value: (doc) => doc.data,
    );
  }

  @override
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc) =>
      instance.getDocument(doc.path);

  @override
  Future<bool> _setDocument(
    DocumentReference<dynamic> doc,
    Map<String, dynamic> data,
  ) =>
      evaluate(() => instance.setDocument(doc.path, data));

  @override
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection) {
    return instance.collectionSnapshots(collection.path).asyncMap((docs) {
      return docs.toMap(
        key: (doc) => DocumentReference(doc.path, collection.parser),
        value: (doc) => doc.data,
      );
    });
  }

  @override
  Stream<DocumentData?> _documentSnapshots(DocumentReference<dynamic> doc) =>
      instance.documentSnapshots(doc.path);
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
