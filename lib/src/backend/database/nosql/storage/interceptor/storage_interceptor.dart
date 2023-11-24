/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';

class StorageInterceptor {
  /// Executed before the reference is passed on to the storage to access the data.
  String modifyReference(String reference) => reference;

  DocumentData preSetDocument(String reference, DocumentData data) => data;
  
  Future<DocumentData?> postGetDocument(Future<DocumentData?> result, String reference) => result;
  Future<bool> postSetDocument(Future<bool> result, String reference, DocumentData data) => result;
  Future<bool> postDeleteDocument(Future<bool> result, String reference) => result;
  Stream<DocumentData?> postDocumentSnapshots(Stream<DocumentData?> result, String reference) => result;
  
  Future<CollectionData> postGetCollection(Future<CollectionData> result, String reference) => result;
  Stream<CollectionData> postCollectionSnapshots(Stream<CollectionData> result, String reference) => result;
}
