/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static LocalStorage? _instance;

  static LocalStorage get instance => _instance ??= LocalStorage._();

  LocalStorage._([String? path]) {
    Hive.initFlutter(path);
  }

  final Map<String, StreamController<Map<String, dynamic>>> _documentSnapshots = {};
  final Map<String, StreamController<List<LocalStorageData>>> _collectionSnapshots = {};

  Future<Box> get _root async {
    await Hive.initFlutter();
    return Hive.openBox("root");
  }

  Future<Box?> _getBox(List<String> pathSegments, {Box? previous, bool forceCreate = false}) async {
    if (pathSegments.isEmpty) return _root;

    previous ??= await _root;
    assert(pathSegments.length % 2 == 0);
    if (pathSegments.length % 2 != 0) return null;

    var collection = "_${pathSegments[0]}";
    var document = pathSegments[1];
    pathSegments.removeRange(0, 2);

    //Checks if collection exists
    if (!previous.containsKey(collection)) {
      if (!forceCreate) return null;

      previous.put(collection, []);
    }
    var docRefs = (await previous.get(collection) as List).cast<String>();

    //Checks if document exists
    if (!docRefs.contains(document)) {
      if (!forceCreate) return null;

      previous.put(collection, [document, ...docRefs]);
    }
    Box newBox = await Hive.openBox(document);

    if (pathSegments.isNotEmpty) {
      return _getBox(
        pathSegments,
        previous: newBox,
        forceCreate: forceCreate,
      );
    }

    return newBox;
  }

  Future<void> setDocument(String path, Map<String, dynamic> data, {bool override = true}) async {
    Box box = (await _getBox(path.split("/"), forceCreate: true))!;
    if (override) await box.clear();

    await box.putAll(data);
    await box.flush();
  }

  Future<Map<String, dynamic>?> getDocument(String path) async {
    Box? box = await _getBox(path.split("/"));
    if (box == null) return null;

    return (box.toMap().cast<String, dynamic>())..removeWhere((key, _) => key.startsWith("_"));
  }

  Future<bool> deleteDocument(String path, [bool? cascade = false]) async {
    Box? box = await _getBox(path.split("/"));
    if (box == null) return true;

    var subDirectories = (box.toMap() as Map<String, List<String>>)
      ..removeWhere((key, _) => !key.startsWith("_"));

    //Remove all data except collections from the document
    if (!(cascade ?? false)) {
      box
        ..clear()
        ..putAll(subDirectories)
        ..flush();
      return true;
    } else {
      var result = await Future.wait(
        subDirectories.mapToList((collection, docs) {
          return docs.map((doc) => deleteDocument("$path/${collection.substring(1)}/$doc"));
        }).expand((e) => e),
      );
      if (result.contains(false)) return false;

      box.deleteFromDisk();
      return true;
    }
  }

//TODO snapshots document

  Future<List<LocalStorageData>> documentsOfCollection(String path) async {
    var segments = path.split("/");
    Box? box = await _getBox(segments.sublist(0, segments.length - 1));
    if (box == null) return [];

    var docs = (box.get("_${segments.last}") as List).cast<String>();

    return await docs.asyncMap((doc) async {
      var docPath = "$path/$doc";

      return LocalStorageData(docPath, (await getDocument(docPath))!);
    });
  }

//TODO snapshots collection
}

class LocalStorageData {
  final String path;
  final Map<String, dynamic> data;

  LocalStorageData(this.path, this.data);
}
