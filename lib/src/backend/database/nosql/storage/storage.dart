/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/foundation.dart';

typedef DocumentData = Map<String, dynamic>;
typedef CollectionData = Map<String, DocumentData>;

abstract class Storage {
  late final StorageState state;

  Storage({StorageState? state}) {
    this.state = state ?? StorageState();
  }

  /// Copies all provided references from one storage to another
  static Future<void> copyAll({
    required Storage from,
    required Storage to,
    required List<Reference> refs,
  }) {
    return refs.asyncMap((ref) {
      switch (ref.runtimeType) {
        case DocumentReference:
          return Document.ref(from, ref).copyTo(to);
        case CollectionReference:
          return Collection.ref(from, ref).copyTo(to);
        default:
          return SynchronousFuture(null);
      }
    });
  }

  /// Set the data of a document, creates new document if not existing.
  /// Returns, if the document was successfully set.
  Future<bool> setDocument(String reference, DocumentData data);

  /// Get the data of the document.
  Future<DocumentData?> getDocument(String reference);

  /// Delete a document by reference.
  /// Returns true after completion if the document does not exist anymore,
  /// also if the document has not existed before.
  Future<bool> deleteDocument(String reference);

  /// Return the stream of the snapshots of the document.
  /// Must dispatch an initial event.
  /// Stream only dispatches events if the document is modified.
  /// The *null* event indicates that the document was deleted, though it
  /// is not necessary to implement.
  Stream<DocumentData?> documentSnapshots(String reference);

  /// Return all documents of a collection.
  /// Must include the data of the documents.
  Future<CollectionData> getCollection(String reference);

  /// Return the stream of the snapshots of the collection.
  /// Must dispatch an initial event.
  /// Stream must dispatch event if...
  /// - Document is created
  /// - Document is deleted
  /// - Document is modified
  /// ...within the collection
  Stream<CollectionData> collectionSnapshots(String reference);
}
