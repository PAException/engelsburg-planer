/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:flutter/foundation.dart';

/// Handles any delayed writes of documents for a specific storage.
class StorageDelayedWriter {
  /// Caches timers for delayed document updates (reference, timer)
  final Map<DocumentReference, Timer> _submitted = {};

  /// Dispose any active timers that will write a document with this reference
  /// to the storage.
  void dispose(DocumentReference document) {
    var write = _submitted[document];
    if (write != null) {
      debugPrint("[${document.id}] disposing delayed write");

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
    debugPrint("[${document.id}] submitted delayed write: $data");
    delayedWrite() async {
      debugPrint("[${document.id}] executing delayed write: $data");
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
