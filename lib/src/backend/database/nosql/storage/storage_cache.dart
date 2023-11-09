/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';

//TODO docs
class StorageCache {
  final Map<DocumentReference, Map<String, dynamic>> _documentCache = {};
  final Map<CollectionReference, Set<DocumentReference>> _collectionCache = {};

  /// Writes the data of the document to the cache and also references the
  /// document in the collection cache if possible.
  void setDocument(DocumentReference document, Map<String, dynamic> data) {
    debugPrint("[${document.id}] updating cached document: $data");
    //Update document cache
    _documentCache[document] = data;

    //Get nullable parent collection
    var parentCollection = document.parent();
    if (parentCollection == null) return;

    //Update parent collection
    var cachedCollection = _collectionCache[parentCollection] ?? {};
    cachedCollection.add(document);

    _collectionCache[parentCollection] = cachedCollection;
  }

  //TODO docs
  Map<String, dynamic>? getDocument(DocumentReference document) {
    var data = _documentCache[document];
    if (data != null) debugPrint("[${document.id}] getting cached document: $data");

    return data;
  }

  //TODO docs
  void removeDocument(DocumentReference document) {
    debugPrint("[${document.id}] removing cached document");
    _documentCache.remove(document);

    //Update parent collection
    var parentCollection = document.parent();
    if (parentCollection == null) return;

    var cachedCollection = _collectionCache[parentCollection];
    cachedCollection?.remove(document);

    if (cachedCollection != null) {
      if (cachedCollection.isNotEmpty) {
        _collectionCache[parentCollection] = cachedCollection;
      } else {
        _collectionCache.remove(parentCollection);
      }
    }
  }

  //TODO docs
  void setCollection(CollectionReference collection, CollectionData collectionData) {
    debugPrint("[${collection.id}] setting cached collection: $collectionData");

    //Map collection data to document references
    var documents = collectionData.mapToList((key, value) {
      var document = DocumentReference(key, collection.parser);

      //Update each document
      setDocument(document, value);

      return document;
    });

    _collectionCache[collection] = documents.toSet();
  }

  //TODO docs
  List<DocumentReference<T>>? getCollection<T>(CollectionReference<T> collection) {
    debugPrint("[${collection.id}] getting cached collection");

    var refs = _collectionCache[collection]?.toList() ?? [];

    return refs.cast<DocumentReference<T>>();
  }

  /// Returns if the data to the given reference, document or collection,
  /// is cached.
  bool contains(Reference<dynamic> reference) {
    switch (reference.runtimeType) {
      case DocumentReference: return _documentCache.containsKey(reference);
      case CollectionReference: return _collectionCache.containsKey(reference);
    }

    return false;
  }
}