/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/storage_interceptor.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';

class PrefixInterceptor extends StorageInterceptor {
  final String? Function() obtainPrefix;

  PrefixInterceptor(this.obtainPrefix);

  PrefixInterceptor.static(String prefix) : obtainPrefix = (() => prefix);

  String? get prefix => obtainPrefix.call();

  Map<String, DocumentData> removePrefixes(Map<String, DocumentData> data) {
    return data.map((key, value) {
      if (prefix != null && key.startsWith("$prefix/")) {
        key =  key.replaceFirst("$prefix/", "");
      }

      return MapEntry(key, value);
    });
  }

  @override
  String modifyReference(String reference) {
    if (prefix == null) return reference;
    if (reference.startsWith("$prefix/")) return reference;

    return "$prefix/$reference";
  }

  @override
  Future<CollectionData> postGetCollection(Future<CollectionData> result, String reference) =>
      result.then((value) => removePrefixes(value));

  @override
  Stream<CollectionData> postCollectionSnapshots(Stream<CollectionData> result, String reference) =>
      result.map((event) => removePrefixes(event));
}
