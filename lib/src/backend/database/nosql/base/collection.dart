/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Collection<T> extends CollectionReference<T> {
  final Storage _storage;

  Collection.ref(this._storage, Reference<T> ref) : super(ref.path, ref.parser);

  const Collection(this._storage, String path, Parser<T> parser)
      : super(path, parser);

  /// References a new document while keeping the current associated storage.
  @override
  Document<T> doc(String name) => Document<T>.ref(_storage, super.doc(name));

  /// Get the corresponding parent of this collection.
  @override
  Document<D> parent<D>(Parser<D> parser) => Document<D>.ref(
    _storage,
    super.parent(parser),
  );

  //TODO docs
  Future<List<Document<T>>> documents() async {
    var cached = _storage.state.getCachedCollection<T>(this);
    if (cached != null) return cached.cast<DocumentReference<T>>().map((e) => e.storage(_storage)).cast<Document<T>>().toList();

    var collectionData = await _storage.getCollection(path);
    _storage.state.cacheCollection(this, collectionData);

    return collectionData.mapToList((key, value) {
      return Document(_storage, key, parser);
    });
  }

  /// Creates a new document within a collection with a new 20 character
  /// alphaNumeric id.
  /// [data] needs to have a [toJson] function.
  /// Returns null if document was not created.
  Future<Document<T>?> addDocument(T data) {
    //Create new random id and assign the document to it
    var id = StringUtils.randomAlphaNumeric(20);
    var newDoc = doc(id);

    //Set the new doc, return doc if set was successful
    return newDoc.set(data).then((value) {
      if (!value) return null;

      return newDoc;
    });
  }

  /// Clears the collection by deleting all documents within.
  Future<void> clear() {
    //Get all documents, delete each one
    return documents().then((docs) => docs.asyncMap((doc) => doc.delete()));
  }

  //TODO docs
  Stream<List<Document<T>>> stream() => _storage.state.getCollectionStream(
    collection: this,
    createNativeStream: (_) => _storage.collectionSnapshots(path),
  ).map((collectionData) {
    return collectionData.mapToList((key, value) {
      return Document(_storage, key, parser);
    });
  });

  /// Copies this collection to another storage.
  Future<List<bool>> copyTo(Storage target) async {
    var docs = await documents();

    //Set each document to the new storage
    return docs.asyncMap((doc) async {
      return doc.storage(target).set(await doc.load());
    });
  }
}
