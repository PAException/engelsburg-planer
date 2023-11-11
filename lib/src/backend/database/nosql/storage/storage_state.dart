/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage_cache.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage_delayed_writer.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage_streams.dart';
import 'package:flutter/cupertino.dart';

//TODO docs
class StorageState {
  late final StorageCache _cache;
  late final StorageStreams _streams;
  late final StorageDelayedWriter _delayedWriter;

  final Map<DocumentReference, Map<String, dynamic>> _delayedWriteData = {};

  StorageState({
    StorageCache? cache,
    StorageStreams? streams,
    StorageDelayedWriter? delayedWriter,
  }) {
    _cache = cache ?? StorageCache();
    _streams = streams ?? StorageStreams();
    _delayedWriter = delayedWriter ?? StorageDelayedWriter();
  }

  //TODO docs
  void preSetDocument(DocumentReference document) {
    if (_DelayedWriteState.submitted.appliesFor(document)) {
      _delayedWriter.dispose(document);
      _DelayedWriteState.none.setFor(document);
    }
  }

  //TODO docs
  void setDelayed<T>(
    Document<T> document,
    T data, {
    Duration delay = const Duration(seconds: 3),
    void Function()? onSuccess,
  }) {
    if (_DelayedWriteState.submitted.appliesFor(document)) {
      _delayedWriter.dispose(document);
    } else {
      _DelayedWriteState.submitted.setFor(document);
    }


    _delayedWriteData[document] = Document.tryParseTypedData(data);
    var previous = _cache.getDocument(document);

    _delayedWriter.submit<T>(
      document: document,
      data: data,
      delay: delay,
      preWrite: (data) {
        _DelayedWriteState.write.setFor(document);

        return data;
      },
      postWrite: (result) {
        _delayedWriteData.remove(document);
        if (result) return;

        debugPrint("[${document.id}] delayed write failed");

        //Revert cache
        _cache.removeDocument(document);
        if (previous != null) _cache.setDocument(document, previous);

        _triggerStreams(document);
      },
    );

    _triggerStreams(document);
  }

  //TODO docs
  void cacheDocument(DocumentReference document, DocumentData data) =>
      _cache.setDocument(document, data);

  //TODO docs
  DocumentData? getCachedDocument(DocumentReference document) {
    return _delayedWriteData[document] ?? _cache.getDocument(document);
  }

  //TODO docs
  void cacheCollection(
    CollectionReference collection,
    CollectionData collectionData,
  ) {
    _cache.setCollection(collection, collectionData);
  }

  //TODO docs
  List<DocumentReference<T>>? getCachedCollection<T>(
    CollectionReference<T> collection,
  ) {
    return _cache.getCollection(collection);
  }

  //TODO docs
  void documentDeleted(DocumentReference document) {
    _cache.removeDocument(document);
    _streams.dispose(document);
    _delayedWriter.dispose(document);

    _DelayedWriteState.none.setFor(document);
  }

  //TODO docs
  Stream<DocumentData?> getDocumentStream<T>({
    required DocumentReference<T> document,
    required Stream<DocumentData?> Function(String path) createNativeStream,
  }) {
    debugPrint("[${document.id}] issued new document stream");

    return _streams.getDocumentStream(
      document: document,
      createNativeStream: createNativeStream,
      intercept: (data) => _interceptDocumentStream(
        document: document,
        data: data,
      ),
    );
  }

  //TODO docs
  Stream<CollectionData> getCollectionStream({
    required CollectionReference collection,
    required Stream<CollectionData> Function(String path) createNativeStream,
  }) {
    return _streams.getCollectionStream(
      collection: collection,
      createNativeStream: createNativeStream,
      intercept: (collectionData) => _interceptCollectionStream(
        collection: collection,
        collectionData: collectionData,
      ),
    );
  }

  //TODO docs
  DocumentData? _interceptDocumentStream({
    required DocumentReference document,
    required DocumentData? data,
    bool updateIsLocal = false,
  }) {
    if (data != null) {
      _cache.setDocument(document, data);
    } else {
      _cache.removeDocument(document);
    }

    if (_DelayedWriteState.submitted.appliesFor(document)) {
      if (updateIsLocal) {
        var latest = _delayedWriteData[document];
        assert(latest != null);

        return latest;
      } else {
        _delayedWriter.dispose(document);
      }
    }
    _DelayedWriteState.none.setFor(document);

    return data;
  }

  //TODO docs
  CollectionData _interceptCollectionStream({
    required CollectionReference collection,
    required CollectionData collectionData,
    bool updateIsLocal = false,
  }) {
    _cache.setCollection(collection, collectionData); //TODO updates documents twice to cache

    return collectionData.map((key, value) {
      debugPrint("$key, $value");
      value = _interceptDocumentStream(
        document: DocumentReference(key, collection.parser),
        data: value,
        updateIsLocal: updateIsLocal,
      )!;
      debugPrint("AFTER: $key, $value");

      return MapEntry(key, value);
    });
  }

  //TODO docs
  void _triggerStreams(DocumentReference document) {
    var parentCollection = document.parent();

    _streams.dispatchLatest(
      document: document,
      interceptDocument: (data) => _interceptDocumentStream(
        document: document,
        data: data,
        updateIsLocal: true,
      ),
      interceptCollection: parentCollection == null
          ? null
          : (collectionData) => _interceptCollectionStream(
                collection: parentCollection,
                collectionData: collectionData,
                updateIsLocal: true,
              ),
    );
  }
}

enum _DelayedWriteState {
  none,
  submitted,
  write,
}

extension _DelayedWriteStates on _DelayedWriteState {
  static final Map<DocumentReference, _DelayedWriteState> _states = {};

  void setFor(DocumentReference document) {
    if (this == _DelayedWriteState.none) {
      _states.remove(document);

      return;
    }

    _states[document] = this;
  }

  bool appliesFor(DocumentReference document) =>
      _states[document] == this || this == _DelayedWriteState.none;
}
