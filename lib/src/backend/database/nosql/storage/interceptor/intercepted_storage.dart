/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/storage_interceptor.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';

class InterceptedStorage extends Storage {
  final Storage storage;
  final List<StorageInterceptor> interceptors;

  InterceptedStorage({
    required this.storage,
    required this.interceptors,
  });

  String _modifyReference(String reference) {
    for (var interceptor in interceptors) {
      reference = interceptor.modifyReference(reference);
    }

    return reference;
  }

  @override
  Future<DocumentData?> getDocument(String reference) {
    var result = storage.getDocument(_modifyReference(reference));

    for (var interceptor in interceptors) {
      result = interceptor.postGetDocument(result, reference);
    }

    return result;
  }

  @override
  Future<bool> setDocument(String reference, DocumentData data) {
    for (var interceptor in interceptors) {
      data = interceptor.preSetDocument(reference, data);
    }

    var result = storage.setDocument(_modifyReference(reference), data);

    for (var interceptor in interceptors) {
      result = interceptor.postSetDocument(result, reference, data);
    }

    return result;
  }

  @override
  Future<bool> deleteDocument(String reference) {
    var result = storage.deleteDocument(_modifyReference(reference));

    for (var interceptor in interceptors) {
      result = interceptor.postDeleteDocument(result, reference);
    }

    return result;
  }

  @override
  Stream<DocumentData?> documentSnapshots(String reference) {
    var result = storage.documentSnapshots(_modifyReference(reference));

    for (var interceptor in interceptors) {
      result = interceptor.postDocumentSnapshots(result, reference);
    }

    return result;
  }

  @override
  Future<CollectionData> getCollection(String reference) {
    var result = storage.getCollection(_modifyReference(reference));

    for (var interceptor in interceptors) {
      result = interceptor.postGetCollection(result, reference);
    }

    return result;
  }

  @override
  Stream<CollectionData> collectionSnapshots(String reference) {
    var result = storage.collectionSnapshots(_modifyReference(reference));

    for (var interceptor in interceptors) {
      result = interceptor.postCollectionSnapshots(result, reference);
    }

    return result;
  }
}

extension StorageExt on Storage {
  Storage withInterceptors(List<StorageInterceptor> interceptors) {
    return InterceptedStorage(storage: this, interceptors: interceptors);
  }
}
