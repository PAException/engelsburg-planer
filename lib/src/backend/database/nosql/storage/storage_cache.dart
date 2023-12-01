/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/logger.dart';

//TODO docs
class StorageCache with Logs<Storage> {
  final Map<DocumentReference, Map<String, dynamic>> _documentCache = {};
  final Map<CollectionReference, Set<DocumentReference>> _collectionCache = {};

  /// Writes the data of the document to the cache and also references the
  /// document in the collection cache if possible.
  void setDocument<T>(DocumentReference<T> document, Map<String, dynamic> data) {
    logger.trace("Updating cached document: $document");
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
    if (data != null) logger.trace("getting cached document: $document");

    return data;
  }

  //TODO docs
  void removeDocument(DocumentReference document) {
    logger.trace("removing cached document: $document");
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
  void setCollection<T>(CollectionReference<T> collection, CollectionData collectionData) {
    logger.trace("setting cached collection: $collection");

    //Map collection data to document references
    var documents = collectionData.mapToList((key, value) {
      var document = DocumentReference<T>(key, collection.parser);

      //Update each document
      setDocument(document, value);

      return document;
    });

    _collectionCache[collection] = documents.toSet();
  }

  //TODO docs
  List<DocumentReference<T>>? getCollection<T>(CollectionReference<T> collection) {
    logger.trace("getting cached collection: $collection");

    var refs = _collectionCache[collection];

    return refs?.map((e) => e.cast(collection.parser)).toList() ?? [];
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