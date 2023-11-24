/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';

//TODO docs
class FirestoreStorage extends Storage {
  final FirebaseFirestore _instance = FirebaseFirestore.instance;

  CollectionData mapCollectionSnapshot(
    String reference,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.toMap(
      key: (doc) => "$reference/${doc.id}",
      value: (doc) => doc.data(),
    );
  }

  @override
  Stream<CollectionData> collectionSnapshots(String reference) {
    return _instance.collection(reference).snapshots().map((snapshot) {
      return mapCollectionSnapshot(reference, snapshot);
    });
  }

  @override
  Future<bool> deleteDocument(String reference) async {
    try {
      await _instance.doc(reference).delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<DocumentData?> documentSnapshots(String reference) {
    return _instance.doc(reference).snapshots().map((event) => event.data());
  }

  @override
  Future<CollectionData> getCollection(String reference) {
    return _instance.collection(reference).get().then((snapshot) {
      return mapCollectionSnapshot(reference, snapshot);
    });
  }

  @override
  Future<DocumentData?> getDocument(String reference) {
    return _instance.doc(reference).get().then((value) => value.data());
  }

  @override
  Future<bool> setDocument(String reference, Map<String, dynamic> data) async {
    try {
      await _instance.doc(reference).set(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
