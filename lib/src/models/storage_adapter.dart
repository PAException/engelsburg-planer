/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/models/local_storage.dart';
import 'package:engelsburg_planer/src/utils/firebase/analytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef Parser<T> = T Function(DocumentData data);
typedef DocumentData = Map<String, dynamic>;
typedef CollectionData<T> = Map<DocumentReference<T>, DocumentData>;

/// Object that refers to something with a blueprint how to build it.
@immutable
abstract class Reference<T> {
  final String path;
  final Parser<T> parser;

  const Reference(this.path, this.parser);

  String get id => path.split("/").last;

  @override
  String toString() => 'Reference{path: $path}';

  @override
  bool operator ==(Object other) => other is Reference && id == other.id;

  @override
  int get hashCode => path.hashCode;
}

/// Same as Reference<T>, but only to documents.
@immutable
class DocumentReference<T> extends Reference<T> {
  const DocumentReference(super.path, super.parser);

  CollectionReference<D> collection<D>(String name, Parser<D> parser) =>
      CollectionReference<D>("$path/$name", parser);

  @nonVirtual
  Document<T> storage(Storage storage) => Document<T>.ref(storage, this);

  Document<T> get offlineStorage => storage(Storage.offline);

  Document<T> get onlineStorage => storage(Storage.online);
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

  Collection<T> get offlineStorage => storage(Storage.offline);

  Collection<T> get onlineStorage => storage(Storage.online);
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Document<T> extends DocumentReference<T> {
  final Storage _storage;

  Document.ref(this._storage, DocumentReference<T> ref)
      : super(_storage.addPrefix(ref.path), ref.parser);

  Document(this._storage, String path, Parser<T> parser)
      : super(_storage.addPrefix(path), parser);

  @override
  Collection<D> collection<D>(String name, Parser<D> parser) =>
      Collection<D>(_storage, name, parser);

  Future<T> load() => _storage.safeData(this);

  T? get data => _storage.data(this);

  Future<bool> set(T data) => _storage.setDocument(this, data);

  void setDelayed(
    T data, {
    bool updateStreams = true,
    Duration delay = const Duration(seconds: 3),
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

  @override
  String toString() => 'Document{path: ${super.path}, data: $data}';
}

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Collection<T> extends CollectionReference<T> {
  final Storage _storage;

  Collection.ref(this._storage, CollectionReference<T> ref)
      : super(_storage.addPrefix(ref.path), ref.parser);

  Collection(this._storage, String path, Parser<T> parser)
      : super(_storage.addPrefix(path), parser);

  @override
  Document<T> doc(String name) => Document<T>.ref(_storage, super.doc(name));

  Future<List<Document<T>>> documents() => _storage.getCollection(this);

  Future<Document<T>?> addDocument(T data) => _storage.addDocument(this, data);

  Future<void> clear() => _storage.clearCollection(this);

  Stream<List<Document<T>>> stream() => _storage.collectionStream(this);

  Future<List<bool>> copyTo(Storage target) async {
    var docs = await documents();

    return docs.asyncMap((doc) => target.setDocument(doc, doc.data));
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

  /// Caches snapshot streams of documents (reference, streams)
  final Map<String, List<StreamController<dynamic>>> _activeDocumentStreams =
      {};
  final Map<String, StreamSubscription<Map<String, dynamic>?>>
      _documentStreams = {};

  /// Caches snapshot streams of collections (reference, stream)
  final Map<String, List<StreamController<dynamic>>> _activeCollectionStreams =
      {};
  final Map<String,
          StreamSubscription<Map<DocumentReference, Map<String, dynamic>>>>
      _collectionStreams = {};

  /// Caches timers for delayed document updates (reference, timer)Map<Stream, List<StreamController<dynamic>>>
  final Map<String, Timer> _delayedDocumentUpdates = {};

  /// Get data if already loaded
  @nonVirtual
  T? data<T>(DocumentReference<dynamic> doc) {
    var data = _data[doc.path];
    if (data == null || data.isEmpty) return null;

    return doc.parser.call(data);
  }

  /// Get data, if not loaded await load
  @nonVirtual
  Future<T> safeData<T>(DocumentReference<dynamic> doc) async =>
      data<T>(doc) ??
      doc.parser.call(_data[doc.path] = await _loadDocument(doc));

  /// Creates a new document within a collection.
  @nonVirtual
  Future<Document<T>?> addDocument<T>(
      CollectionReference<T> collection, dynamic data) {
    var id = StringUtils.randomAlphaNumeric(20);
    var createDocRef = collection.doc(id);

    return setDocument(createDocRef, data).then((value) {
      if (!value) return null;

      return createDocRef.storage(this);
    });
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
      if (kDebugMode) rethrow;
      return false;
    } catch (e) {
      debugPrint("Document cannot be set, unknown error.");
      if (kDebugMode) rethrow;
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
    T documentData, {
    bool updateStreams = true,
    Duration delay = const Duration(seconds: 3),
  }) {
    String key = doc.path;

    //Cancel any active timer for this document
    _delayedDocumentUpdates[key]?.cancel();

    //Set timer that sets data after delay
    _delayedDocumentUpdates[key] = Timer(delay, () async {
      var result = await setDocument(doc, documentData);
      _delayedDocumentUpdates.remove(key);

      //If update fails update stream
      if (!result) {
        //Revert changes to document cache
        _loadDocument(doc).then((value) => _data[key] = value);

        var documentControllers = _activeCollectionStreams[key];
        if (documentControllers != null && documentControllers.isNotEmpty) {
          for (var controller in documentControllers) {
            controller.add(documentData);
          }
        }

        var collectionControllers = _activeCollectionStreams[key];
        if (collectionControllers != null && collectionControllers.isNotEmpty) {
          //Parse parent collection of document
          var collectionPath = key.substring(0, key.lastIndexOf("/"));
          var collection = Collection<T>(this, collectionPath, doc.parser);

          //Get current documents and add to stream
          getCollection(collection).then((docs) {
            for (var controller in collectionControllers) {
              controller.add(docs);
            }
          });
        }
      }
    });

    try {
      //Data will only be written to cache, no information will be added to stream
      _data[key] = (documentData as dynamic).toJson();
    } on NoSuchMethodError {
      debugPrint("Document cannot be set, data cannot be parsed into json.");
      if (kDebugMode) rethrow;
    }

    if (!updateStreams) return;

    var documentControllers = _activeDocumentStreams[key];
    if (documentControllers != null && documentControllers.isNotEmpty) {
      for (var controller in documentControllers) {
        controller.add(documentData);
      }
    }

    var collectionPath = key.substring(0, key.lastIndexOf("/"));
    var collectionControllers = _activeCollectionStreams[collectionPath];
    if (collectionControllers != null && collectionControllers.isNotEmpty) {
      //Parse parent collection of document
      var collection = Collection<T>(this, collectionPath, doc.parser);

      //Get current documents and add to stream
      getCollection(collection, updateCache: false).then((docs) {
        for (var controller in collectionControllers) {
          controller.add(docs);
        }
      });
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
  Future<List<Document<T>>> getCollection<T>(CollectionReference<T> collection,
      {bool updateCache = true}) async {
    return ((await _getCollection(collection))
          ..removeWhere((key, value) => value.isEmpty))
        .mapToList((ref, value) {
      if (updateCache) _data[ref.path] = value;

      return Document<T>.ref(this, ref);
    });
  }

  /// Deletes all documents within a collection.
  @nonVirtual
  Future<void> clearCollection(CollectionReference<dynamic> collection) async {
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
    String key = addPrefix(doc.path);

    //Start to fetch the latest data
    var latestData = Future<T?>.value(doc.load()).onError((_, __) => null);

    //Create new stream controller and add to list
    var newController = StreamController<T?>();
    newController.onCancel = () {
      var controllers = _activeDocumentStreams[key];
      controllers?.remove(newController);
      if (controllers?.isEmpty ?? false) {
        _documentStreams[key]?.cancel();
        _documentStreams.remove(key);
      }
    };

    var controllers = _activeDocumentStreams[key]?.toList() ?? [];
    controllers.add(newController);
    _activeDocumentStreams[key] = controllers;

    void handleData(Map<String, dynamic>? event) {
      if (event == null) {
        //on null close stream and remove data, the document was deleted
        _data.remove(key);
        for (var controller in controllers) {
          if (!controller.isClosed) controller.add(null);
          controller.close();
        }
        _documentStreams[key]?.cancel();
      } else {
        //add new snapshot to stream and update data
        _data[key] = event;
        for (var controller in controllers) {
          controller.add(doc.parser.call(event));
        }
      }
    }

    //Update subscription or get new
    var subscription = _documentStreams[key]?..onData(handleData);
    subscription ??= _documentSnapshots(doc).listen(handleData);

    latestData.then((value) => newController.add(value));
    return newController.stream;
  }

  /// Get a stream of snapshots of the collection.
  /// An event is dispatched if a document was created, modified or deleted.
  @nonVirtual
  Stream<List<Document<T>>> collectionStream<T>(Collection<T> collection) {
    String key = addPrefix(collection.path);

    //Start to fetch the latest data
    var latestData = collection.documents();

    //Create new stream controller and add to list
    var newController = StreamController<List<Document<T>>>();
    newController.onCancel = () {
      var controllers = _activeCollectionStreams[key];
      controllers?.remove(newController);
      if (controllers?.isEmpty ?? false) {
        _collectionStreams[key]?.cancel();
        _collectionStreams.remove(key);
      }
    };

    var controllers = _activeCollectionStreams[key]?.toList() ?? [];
    controllers.add(newController);
    _activeCollectionStreams[key] = controllers;

    void handleData(Map<DocumentReference, Map<String, dynamic>> docs) {
      //Add new snapshot of collection to stream and update data
      newController.add(docs.mapToList((ref, value) {
        _data[ref.path] = value;

        return Document<T>.ref(this, ref as DocumentReference<T>);
      }));
    }

    //Update subscription or get new
    var subscription = _collectionStreams[key]?..onData(handleData);
    subscription ??= _collectionSnapshots(collection).listen(handleData);

    latestData.then((value) => newController.add(value));
    return newController.stream;
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
  Future<CollectionData<T>> _getCollection<T>(
      CollectionReference<T> collection);

  /// Return the stream of the snapshots of the collection.
  /// Stream must dispatch event if...
  /// - Document is created
  /// - Document is deleted
  /// - Document is modified
  /// ...within the collection
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection);

  String? get prefix;

  @nonVirtual
  String addPrefix(String path) {
    if (prefix == null) return path;
    if (path.startsWith("$prefix/")) return path;

    return "$prefix/$path";
  }

  @nonVirtual
  String removePrefix(String path) {
    if (prefix == null) return path;
    if (!path.startsWith("$prefix/")) return path;

    return path.replaceFirst("$prefix/", "");
  }
}

class FirestoreStorageImpl extends Storage {
  static FirebaseFirestore instance = FirebaseFirestore.instance;

  @override
  String? get prefix => FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<bool> _setDocument(
          DocumentReference<dynamic> doc, Map<String, dynamic> data) =>
      evaluate(() => instance.doc(addPrefix(doc.path)).set(data)).then((value) {
        Analytics.database.write(this);

        return value;
      });

  @override
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc) =>
      instance.doc(addPrefix(doc.path)).get().then((value) {
        Analytics.database.read(this);

        return value.data() ?? {};
      });

  @override
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc) =>
      evaluate(() => instance.doc(addPrefix(doc.path)).delete().then((value) {
            Analytics.database.delete(this);

            return value;
          }));

  @override
  Stream<DocumentData?> _documentSnapshots(DocumentReference<dynamic> doc) =>
      instance.doc(addPrefix(doc.path)).snapshots().map((event) {
        Analytics.database.read(this);

        return event.data();
      });

  @override
  Future<CollectionData<T>> _getCollection<T>(
      CollectionReference<T> collection) async {
    var snapshot = await instance.collection(addPrefix(collection.path)).get();

    return snapshot.docs.toMap(
      key: (doc) => DocumentReference<T>(
          addPrefix(doc.reference.path), collection.parser),
      value: (doc) {
        Analytics.database.read(this);

        return doc.data();
      },
    );
  }

  @override
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection) {
    var snapshots = instance.collection(addPrefix(collection.path)).snapshots();

    return snapshots.map((snapshot) {
      return snapshot.docs.toMap(
        key: (doc) =>
            DocumentReference(addPrefix(doc.reference.path), collection.parser),
        value: (doc) {
          Analytics.database.read(this);

          return doc.data();
        },
      );
    });
  }
}

class LocalStorageImpl extends Storage {
  static LocalStorage instance = LocalStorage.instance;

  @override
  String? get prefix => "local";

  @override
  Future<bool> _deleteDocument(DocumentReference<dynamic> doc) =>
      instance.deleteDocument(addPrefix(doc.path)).then((value) {
        Analytics.database.delete(this);

        return value;
      });

  @override
  Future<CollectionData<T>> _getCollection<T>(
      CollectionReference<T> collection) async {
    var docs = await instance.getCollection(addPrefix(collection.path));

    return docs.toMap(
      key: (doc) => DocumentReference(addPrefix(doc.path), collection.parser),
      value: (doc) {
        Analytics.database.read(this);

        return doc.data;
      },
    );
  }

  @override
  Future<DocumentData> _loadDocument(DocumentReference<dynamic> doc) =>
      instance.getDocument(addPrefix(doc.path)).then((value) {
        Analytics.database.read(this);

        return value;
      });

  @override
  Future<bool> _setDocument(
    DocumentReference<dynamic> doc,
    Map<String, dynamic> data,
  ) =>
      evaluate(() => instance.setDocument(addPrefix(doc.path), data))
          .then((value) {
        Analytics.database.write(this);

        return value;
      });

  @override
  Stream<CollectionData<T>> _collectionSnapshots<T>(Collection<T> collection) {
    return instance
        .collectionSnapshots(addPrefix(collection.path))
        .asyncMap((docs) {
      return docs.toMap(
        key: (doc) => DocumentReference(addPrefix(doc.path), collection.parser),
        value: (doc) {
          Analytics.database.read(this);

          return doc.data;
        },
      );
    });
  }

  @override
  Stream<DocumentData?> _documentSnapshots(DocumentReference<dynamic> doc) =>
      instance.documentSnapshots(addPrefix(doc.path)).map((event) {
        Analytics.database.read(this);

        return event;
      });
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

class CollectionStreamBuilder<T> extends StatelessWidget {
  const CollectionStreamBuilder({
    super.key,
    required this.collection,
    required this.itemBuilder,
    this.separatorBuilder,
    this.loading,
    this.empty,
  });

  final Collection<T> collection;
  final Widget Function(BuildContext context, Document<T> doc) itemBuilder;
  final Widget Function(BuildContext context, Document<T> doc)?
      separatorBuilder;
  final Widget? loading;
  final Widget? empty;

  final Widget kLoading = const Center(child: CircularProgressIndicator());
  final Widget kEmpty = const Center(child: Text("Not Found"));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Document<T>>>(
      stream: collection.stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? kLoading;
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return empty ?? loading ?? kLoading;
        }

        var data = snapshot.data!;
        return ListView.separated(
          itemBuilder: (context, index) =>
              itemBuilder.call(context, data[index]),
          separatorBuilder: (context, index) =>
              separatorBuilder?.call(context, data[index]) ?? Container(),
          itemCount: data.length,
        );
      },
    );
  }
}

class StreamConsumer<T> extends StatelessWidget {
  const StreamConsumer({
    Key? key,
    required this.doc,
    required this.itemBuilder,
    this.errorBuilder,
  }) : super(key: key);

  final Document<T> doc;
  final Widget Function(BuildContext context, Document<T> doc, T t) itemBuilder;
  final Widget? Function(BuildContext context, Document<T> doc, Object? error)?
      errorBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T?>(
      stream: doc.stream(),
      builder: (context, snapshot) {
        if (snapshot.hasData)
          return itemBuilder.call(context, doc, snapshot.data as T);

        return errorBuilder?.call(context, doc, snapshot.error) ?? Container();
      },
    );
  }
}

class NullableStreamConsumer<T> extends StatelessWidget {
  const NullableStreamConsumer({
    Key? key,
    required this.doc,
    required this.itemBuilder,
    this.errorBuilder,
  }) : super(key: key);

  final Document<T>? doc;
  final Widget Function(BuildContext context, Document<T>? doc, T? t)
      itemBuilder;
  final Widget? Function(BuildContext context, Document<T>? doc, Object? error)?
      errorBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T?>(
      stream: doc?.stream(),
      builder: (context, snapshot) {
        if (!snapshot.hasError) {
          return itemBuilder.call(context, doc, snapshot.data);
        }

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
  final Widget? Function(BuildContext context, Document doc, Object? error)?
      errorBuilder;

  @override
  Widget build(BuildContext context) {
    doc.load();
    V? v;
    late Widget currentBuild;

    return StreamConsumer<T>(
      doc: doc,
      errorBuilder: errorBuilder,
      itemBuilder: (context, doc, t) {
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
