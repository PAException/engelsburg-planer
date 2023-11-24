/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/storage_interceptor.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';

class AnalyticsInterceptor extends StorageInterceptor {
  final void Function(String reference)? onRead;
  final void Function(String reference)? onWrite;
  final void Function(String reference)? onDelete;

  AnalyticsInterceptor({this.onRead, this.onWrite, this.onDelete});

  T _wrapCallback<T>(T result, void Function(String)? callback, String reference) {
    callback?.call(reference);

    return result;
  }

  @override
  Future<DocumentData?> postGetDocument(Future<DocumentData?> result, String reference) =>
      result.then((value) => _wrapCallback(result, onRead, reference));
  @override
  Future<bool> postSetDocument(Future<bool> result, String reference, DocumentData data) =>
      result.then((value) => _wrapCallback(result, onWrite, reference));
  @override
  Future<bool> postDeleteDocument(Future<bool> result, String reference) =>
      result.then((value) => _wrapCallback(result, onDelete, reference));
  @override
  Stream<DocumentData?> postDocumentSnapshots(Stream<DocumentData?> result, String reference) =>
      result.map((value) => _wrapCallback(value, onRead, reference));

  @override
  Future<CollectionData> postGetCollection(Future<CollectionData> result, String reference) {
    return result.then((value) {
      return value.map((key, value) {
        return _wrapCallback(MapEntry(key, value), onRead, reference);
      });
   });
  }

  @override
  Stream<CollectionData> postCollectionSnapshots(Stream<CollectionData> result, String reference) =>
      result.map((event) => _wrapCallback(event, onRead, reference));
}
