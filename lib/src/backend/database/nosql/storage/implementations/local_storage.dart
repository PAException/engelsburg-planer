/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/local_nosql_database.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';

//TODO docs
class LocalStorage extends Storage {
  static final LocalNosqlDatabase instance = LocalNosqlDatabase.instance;

  CollectionData mapCollection(List<LocalStorageData> data) {
    return data.toMap(key: (doc) => doc.path, value: (doc) => doc.data);
  }

  @override
  Future<DocumentData?> getDocument(String reference) {
    return instance.getDocument(reference);
  }

  @override
  Future<bool> setDocument(String reference, Map<String, dynamic> data) {
    return instance.setDocument(reference, data).then((_) => true, onError: (_) => false);
  }

  @override
  Future<bool> deleteDocument(String reference) {
    return instance.deleteDocument(reference);
  }

  @override
  Stream<DocumentData?> documentSnapshots(String reference) {
    return instance.documentSnapshots(reference);
  }

  @override
  Future<CollectionData> getCollection(String reference) {
    return instance.getCollection(reference).then((value) => mapCollection(value));
  }

  @override
  Stream<CollectionData> collectionSnapshots(String reference) {
    return instance.collectionSnapshots(reference).map((event) => mapCollection(event));
  }

}
