/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:hive_flutter/hive_flutter.dart';

//TODO migrate LocalStorageData to typedef LocalStorageData = Map<String, Map<String, dynamic>>
/// Extends the [HiveDocumentDatabaseAdapter] by adding streams of
/// documents and collections, similar to Firestore.
class LocalNosqlDatabase {
  static LocalNosqlDatabase? _instance;

  static LocalNosqlDatabase get instance => _instance ??= LocalNosqlDatabase._();

  LocalNosqlDatabase._();

  final HiveDocumentDatabaseAdapter _adapter =
      HiveDocumentDatabaseAdapter("local_storage");

  /// Stores all active document and collections streams
  final Map<String, StreamController<Map<String, dynamic>?>>
      _documentSnapshots = {};
  final Map<String, StreamController<List<LocalStorageData>>>
      _collectionSnapshots = {};

  /// see [HiveDocumentDatabaseAdapter#setDocument]
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool override = true,
  }) async {
    //Wait for adapter to set document
    await _adapter.setDocument(path, data, override: override);

    //If document has active stream add new data to stream
    var snapshotController = _documentSnapshots[path];
    if (snapshotController != null) snapshotController.add(data);

    //If parent collection has active stream add updated docs to stream
    var parent = path.substring(0, path.lastIndexOf("/"));
    var collectionSnapshotController = _collectionSnapshots[parent];
    if (collectionSnapshotController != null) {
      getCollection(parent).then((docs) {
        _collectionSnapshots[parent]?.add(docs);
      });
    }
  }

  /// see [HiveDocumentDatabaseAdapter#getDocument]
  Future<Map<String, dynamic>> getDocument(String path) =>
      _adapter.getDocument(path);

  /// see [HiveDocumentDatabaseAdapter#deleteDocument]
  Future<bool> deleteDocument(String path, [bool? cascade = false]) async {
    //Wait for adapter to delete document
    var result = await _adapter.deleteDocument(path);

    if (!result) return result;

    //If document has active stream add null to stream, close and remove reference
    var documentSnapshotController = _documentSnapshots[path];
    if (documentSnapshotController != null) {
      documentSnapshotController.add(null);
      documentSnapshotController.close();
      _documentSnapshots.remove(path);
    }

    //If parent collection has active stream add updated docs to stream
    var parent = path.substring(0, path.lastIndexOf("/"));
    var collectionSnapshotController = _collectionSnapshots[parent];
    if (collectionSnapshotController != null) {
      getCollection(parent).then((docs) {
        _collectionSnapshots[parent]?.add(docs);
      });
    }

    return true;
  }

  /// see [HiveDocumentDatabaseAdapter#getCollection]
  Future<List<LocalStorageData>> getCollection(String path) async =>
      _adapter.getCollection(path);

  /// Returns a stream of snapshots of the referenced document.
  Stream<Map<String, dynamic>?> documentSnapshots(String path) {
    //Get latest data
    var latest = _adapter.getDocument(path);

    //If document stream for path exists return this stream
    var controller = _documentSnapshots[path];
    if (controller != null) return controller.stream;

    //If not create new stream, that automatically closes, if there are no active listeners
    var newController = StreamController<Map<String, dynamic>?>.broadcast(
      onCancel: () {
        _documentSnapshots[path]?.close();
        _documentSnapshots.remove(path);
      },
    );

    //Save new stream and return
    latest.then((value) => newController.add(value));
    return (_documentSnapshots[path] = newController).stream;
  }

  /// Returns a stream of snapshots of the referenced collection.
  Stream<List<LocalStorageData>> collectionSnapshots(String path) {
    //Get latest collectionData
    var latest = _adapter.getCollection(path);

    //If collection stream for path exists return this stream
    var controller = _collectionSnapshots[path];
    if (controller != null) return controller.stream;

    //If not create new stream, that automatically closes, if there are no active listeners
    var newController = StreamController<List<LocalStorageData>>.broadcast(
      onCancel: () {
        _collectionSnapshots[path]?.close();
        _collectionSnapshots.remove(path);
      },
    );

    //Save new stream and return
    latest.then((value) => newController.add(value));
    return (_collectionSnapshots[path] = newController).stream;
  }
}

/// Adapter for Hive to behave like a document based Database,
/// similar to Firestore.
///
/// Documents are treated as boxes of [Hive]. Collections are entries within a
/// document that start with an underscore. That entry is a list of paths
/// that are pointing to the corresponding documents.
class HiveDocumentDatabaseAdapter {
  late Future _initialize;

  HiveDocumentDatabaseAdapter([String? path]) {
    _initialize = Hive.initFlutter(path);
  }

  /// Get the root document.
  /// Waits till [Hive] is initialized.
  Future<Box> get _root async {
    await _initialize;
    return Hive.openBox("root");
  }

  /// Recursive get the corresponding document (Box).
  /// Length of [pathSegments] must be even.
  /// Name of document must not start with and underscore.
  Future<Box?> _getBox(
    List<String> pathSegments, {
    Box? previous,
    bool forceCreate = false,
  }) async {
    //If there is not path provided return the root document
    if (pathSegments.isEmpty) return _root;

    //Check if pathSegments are even
    previous ??= await _root;
    assert(pathSegments.length % 2 == 0);
    if (pathSegments.length % 2 != 0) return null;

    //Extract next collection and document, remove them from pathSegments
    var collection = "_${pathSegments[0]}";
    var document = pathSegments[1];
    pathSegments.removeRange(0, 2);
    assert(!document.startsWith("_"));
    if (document.startsWith("_")) return null;

    //Checks if collection exists
    if (!previous.containsKey(collection)) {
      //If collection does not exist and should not be created return null
      if (!forceCreate) return null;

      //Otherwise create collection
      previous.put(collection, []);
    }

    //Get documents of that collection, list can be empty
    var docRefs = (await previous.get(collection) as List).cast<String>();

    //Checks if document exists
    if (!docRefs.contains(document)) {
      //If document does not exist and should not be created return null
      if (!forceCreate) return null;

      //Otherwise put document in collection
      previous.put(collection, [document, ...docRefs]);
    }
    //Get box of document, can be empty
    Box newBox = await Hive.openBox(document);

    //If there are still pathSegments get box by recursion.
    if (pathSegments.isNotEmpty) {
      return _getBox(
        pathSegments,
        previous: newBox,
        forceCreate: forceCreate,
      );
    }

    //If pathSegments is empty return current box
    return newBox;
  }

  /// Set the data of a document by provided path and data.
  /// If override is true the data of the current document will be deleted
  /// before the new data is set. This does not affect the referenced
  /// collections of the document.
  Future<void> setDocument(
    String path,
    Map<String, dynamic> data, {
    bool override = true,
  }) async {
    //Get box by splitting the path into segments
    Box box = (await _getBox(path.split("/"), forceCreate: true))!;

    if (override) {
      //Get all entries of box that are referring to a collection
      Map collectionRefs = box.toMap()
        ..removeWhere((key, _) => !(key as String).startsWith("_"));

      //Add collection refs to data to be set and clear box
      data.addAll(collectionRefs.cast<String, dynamic>());
      await box.clear();
    }

    //Update data and flush
    await box.putAll(data);
    return box.flush();
  }

  /// Get the data of the document by provided path.
  /// If the document does not exist an empty map is returned.
  Future<Map<String, dynamic>> getDocument(String path) async {
    //Get the documents box, if it does not exist return null
    Box? box = await _getBox(path.split("/"));
    if (box == null) return {};

    //Extract data of the box and remove collection references
    var data = box.toMap().cast<String, dynamic>()
      ..removeWhere((key, _) => key.startsWith("_"));

    return data;
  }

  /// Delete a document by path. If cascade is true collections within the
  /// document will also be deleted.
  /// Returns if document does not exist after completion.
  Future<bool> deleteDocument(String path, [bool? cascade = false]) async {
    //Get box, if it does not exist return null
    var segments = path.split("/");
    Box? box = await _getBox(path.split("/"));
    if (box == null) return true;

    //Extract subdirectories
    var subDirectories = box.toMap()
      ..removeWhere((key, _) => !key.startsWith("_"));

    //Remove all data except collections from the document
    if (!(cascade ?? false)) {
      if (subDirectories.isEmpty) {
        //Remove reference from parent collection
        var docRef = segments.removeLast();
        var parentCollection = segments.removeLast();
        var parentBox = await _getBox(segments);
        if (parentBox != null) {
          var docs = parentBox.get("_$parentCollection") as List;
          docs.cast<String>().removeWhere((ref) => ref == docRef);
          await parentBox.put("_$parentCollection", docs);
          parentBox.flush();
        }

        //Delete box when finished
        await box.deleteFromDisk();
        return true;
      }

      await box.clear();
      await box.putAll(subDirectories);
      await box.flush();
    } else {
      //If cascade is true remove all subDirectories
      var result = await Future.wait(
        subDirectories.mapToList((collection, docs) {
          var collectionRef = "$path/${collection.substring(1)}";

          return docs.map((doc) => deleteDocument("$collectionRef/$doc"));
        }).expand((e) => e),
      );
      //If any of the result contains false a box could not been removed
      if (result.contains(false)) return false;

      box.deleteFromDisk();
    }

    return true;
  }

  /// Get all documents with data of the collection by provided path.
  Future<List<LocalStorageData>> getCollection(String path) async {
    //Get the box of the box that provides information about the collection.
    var segments = path.split("/");
    Box? box = await _getBox(segments.sublist(0, segments.length - 1));
    if (box == null) return [];

    //Get actual document references of the collection
    var entry = box.get("_${segments.last}");
    if (entry == null) return [];
    var docs = (entry as List).cast<String>();

    //Get data of all fetched documents
    return docs.asyncMap((doc) async {
      var docPath = "$path/$doc";

      return LocalStorageData(docPath, (await getDocument(docPath)));
    });
  }
}

///Util class to transfer path and data of a document.
class LocalStorageData {
  final String path;
  final Map<String, dynamic> data;

  LocalStorageData(this.path, this.data);

  @override
  String toString() {
    return 'LocalStorageData{path: $path, data: $data}';
  }
}
