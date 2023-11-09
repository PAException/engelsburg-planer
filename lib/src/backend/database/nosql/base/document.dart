/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:flutter/foundation.dart';

/// Refers to an object in a specific Storage, that handles all operations of the document.
@immutable
class Document<T> extends DocumentReference<T> {
  final Storage _storage;

  Document.ref(this._storage, Reference<T> ref) : super(ref.path, ref.parser);

  const Document(this._storage, String path, Parser<T> parser)
      : super(path, parser);

  /// References a new collection while keeping the current associated storage.
  @override
  Collection<D> collection<D>(String name, Parser<D> parser) =>
      Collection<D>.ref(_storage, super.collection(name, parser));

  /// Get the corresponding parent of this document.
  @override
  Collection<T>? parent() {
    var parent = super.parent();
    if (parent == null) return null;

    return Collection<T>.ref(_storage, parent);
  }

  /// Get the data of this document if it has already been cached.
  T? get data {
    var cached = _storage.state.getCachedDocument(this);
    if (cached == null) return null;

    return parser.call(cached);
  }

  /// Try to call the toJson() function on an object that must return
  /// Map<String, dynamic>. If theres no such function an empty map is returned.
  /// In debugMode the error is also rethrown.
  static DocumentData tryParseTypedData(dynamic data) {
    try {
      return (data as dynamic).toJson();
    } catch (_) {
      debugPrint("Document cannot be set, data cannot be parsed into json.");
      if (kDebugMode) rethrow;
      return {};
    }
  }

  /// Load a document from storage.
  /// If the document does not exist and [emptyOnNull] is true the parser will
  /// be called with an empty list. If [emptyOnNull] is false a state error is
  /// thrown.
  Future<T> load({bool emptyOnNull = true}) async {
    //Return cached data if present
    var data = this.data;
    if (data != null) return data;

    //Read new data and write to cache if not null
    var raw = await _storage.getDocument(path);
    if (raw != null) _storage.state.cacheDocument(this, raw);

    //If wanted throw error if raw data is null
    if (raw == null && !emptyOnNull) {
      throw StateError("Loaded document does not exist");
    }

    return parser.call(raw ?? {});
  }

  /// Sets data of a document in the storage.
  /// [data] needs to have a [toJson] function.
  /// Returns true if the document was created.
  Future<bool> set(T data) async {
    //Try parse data to json, return false if fails
    var parsed = tryParseTypedData(data);
    if (parsed.isEmpty) return false;

    _storage.state.preSetDocument(this);

    //Wait to set document, if successful write to cache
    bool status = await _storage.setDocument(path, parsed);
    if (status) _storage.state.cacheDocument(this, parsed);

    return status;
  }

  /// Sets [data] after a given [delay].
  /// If the update of the document fails the streams will be added docs,
  /// as if the changes were reverted. Same goes for the cache.
  /// If the write of the document succeeds [onSuccess] is executed if given.
  void setDelayed(
    T data, {
    Duration delay = const Duration(seconds: 3),
    void Function()? onSuccess,
  }) {
    _storage.state.setDelayed(this, data, delay: delay, onSuccess: onSuccess);
  }

  /// Delete this document. Returns if the document does not exist after delete
  /// operation. Also true if it has not existed before.
  Future<bool> delete() async {
    var result = await _storage.deleteDocument(path);
    if (result) _storage.state.documentDeleted(this);

    return result;
  }

  //TODO docs
  Stream<T?> stream() => _storage.state.getDocumentStream(
    document: this,
    createNativeStream: (_) => _storage.documentSnapshots(path),
  ).map((data) {
    if (data == null) return null;

    return parser.call(data);
  });

  /// Copies this document to another the provided [target] storage. Returns if
  /// the operation was successful.
  Future<bool> copyTo(Storage target) async =>
      target.setDocument(path, tryParseTypedData(await load()));

  @override
  String toString() => 'Document{path: ${super.path}, data: $data}';
}
