/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/utils/logger.dart';

/// Handles any delayed writes of documents for a specific storage.
class StorageDelayedWriter with Logs<Storage> {
  /// Caches timers for delayed document updates (reference, timer)
  final Map<DocumentReference, Timer> _submitted = {};

  /// Dispose any active timers that will write a document with this reference
  /// to the storage.
  void dispose(DocumentReference document) {
    var write = _submitted[document];
    if (write != null) {
      logger.trace("Disposing delayed write for document: $document");

      write.cancel();
      _submitted.remove(document);
    }
  }

  /// Submit a [document] with typed [data] that will be wrote to the storage
  /// after a given [delay]. After the write [postWrite] will be called
  /// with the corresponding result.
  ///
  /// This function only takes care of the delayed write itself! It does not
  /// modify any cache or stream before or after writing!
  void submit<T>({
    required Document<T> document,
    required T data,
    required Duration delay,
    T Function(T data)? preWrite,
    void Function(bool result)? postWrite,
  }) {
    logger.trace("Submitted delayed write for document: $document");
    delayedWrite() async {
      logger.trace("Executing delayed write for document: $document");
      //Remove this timer from the submitted document writes
      _submitted.remove(document);

      if (preWrite != null) data = preWrite.call(data);

      //Execute the write
      var result = await document.set(data);

      postWrite?.call(result);
    }

    //Set timer that sets data after delay
    _submitted[document] = Timer(delay, delayedWrite);
  }
}
