/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:flutter/cupertino.dart';

typedef DocumentStreamSub = StreamSubscription<DocumentData?>;
typedef CollectionStreamSub = StreamSubscription<CollectionData>;

//TODO docs
class StorageStreams {
  /// Caches snapshot streams of documents (reference, streams)
  final Map<DocumentReference, List<StreamController>> _documentStreams = {};
  final Map<DocumentReference, DocumentStreamSub> _documentSubscriptions = {};

  /// Caches snapshot streams of collections (reference, stream)
  final Map<CollectionReference, List<StreamController>> _collectionStreams =
      {};
  final Map<CollectionReference, CollectionStreamSub> _collectionSubscriptions =
      {};

  //TODO docs
  final Map<DocumentReference, DocumentData?> _latestDocumentData = {};
  final Map<CollectionReference, CollectionData> _latestCollectionData = {};

  /// Creates a StreamController with given type [D] that will handle itself.
  /// If the corresponding stream is canceled the controller will remove itself
  /// from [streams].
  ///
  /// Also if the removed controller was the last one, the subscription in
  /// [subs] to that [reference] will be cancelled.
  /// The returned controller will be added to [streams].
  StreamController<D> _createStreamController<D>({
    required Reference reference,
    required Map<Reference, List<StreamController>> streams,
    required Map<Reference, StreamSubscription> subs,
  }) {
    //Initiate the controller
    var newController = StreamController<D>();

    //If stream is canceled remove controller from the list
    newController.onCancel = () {
      var controllers = streams[reference];
      controllers?.remove(newController);

      //If there are no more active controllers cancel and remove subscription
      if (controllers?.isEmpty ?? false) {
        subs[reference]?.cancel();
        subs.remove(reference);
      }
    };

    //Add the controller to the list and save
    var controllers = streams[reference]?.toList() ?? [];
    controllers.add(newController);
    streams[reference] = controllers;

    return newController;
  }

  /// Get a stream of [document]. The stream will receive a first event with
  /// the current data of the document. Every other event will be an update of
  /// the data.
  ///
  /// If the event is [null] this is an indication that the document was
  /// deleted, however the closure of the stream itself should be crucial event
  /// that the document was deleted.
  Stream<DocumentData?> getDocumentStream({
    required DocumentReference document,
    required Stream<DocumentData?> Function(String) createNativeStream,
    DocumentData? Function(DocumentData? data)? intercept,
  }) {
    debugPrint("[${document.id}] creating new document stream");

    //Create new stream controller and add to list
    var newController = _createStreamController<DocumentData?>(
      reference: document,
      streams: _documentStreams,
      subs: _documentSubscriptions,
    );

    //Handles the data event that will be dispatched from the subscription
    void handleData(DocumentData? data) {
      debugPrint("[${document.id}] handling new data of streamed document");

      _latestDocumentData[document] = data;

      _dispatchDocument(
        document: document,
        data: data,
        intercept: intercept,
      );
    }

    //Update subscription or get new
    var subscription = _documentSubscriptions[document];
    if (subscription == null) {
      var stream = createNativeStream.call(document.path);
      _documentSubscriptions[document] = stream.listen(handleData);
    } else {
      _dispatchDocument(
        document: document,
        data: _latestDocumentData[document],
        intercept: intercept,
      );
    }

    return newController.stream;
  }

  /// Get a stream of [collection]. The stream will receive a first event with
  /// the current documents of the [collection]. Every other event will be an
  /// update of those document. This stream will dispatch an event if a
  /// document is *added*, *deleted* or *modified*. This stream will never close
  /// on itself, because the collection cannot be deleted, it can only contain
  /// no documents.
  Stream<CollectionData> getCollectionStream({
    required CollectionReference collection,
    required Stream<CollectionData> Function(String) createNativeStream,
    CollectionData Function(CollectionData collectionData)? intercept,
  }) {
    debugPrint("[${collection.id}] creating new collection stream");

    //Create new stream controller and add to list
    var newController = _createStreamController<CollectionData>(
      reference: collection,
      streams: _collectionStreams,
      subs: _collectionSubscriptions,
    );

    //Handles the data event that will be dispatched from the subscription
    void handleData(CollectionData collectionData) {
      debugPrint("[${collection.id}] handling new data of streamed collection");

      _latestCollectionData[collection] = collectionData;

      _dispatchCollection(
        collection: collection,
        collectionData: collectionData,
        intercept: intercept,
      );
    }

    //Update subscription or get new
    var subscription = _collectionSubscriptions[collection];
    if (subscription == null) {
      var stream = createNativeStream.call(collection.path);

      //Save the stream subscription
      _collectionSubscriptions[collection] = stream.listen(handleData);
    } else {
      _dispatchCollection(
        collection: collection,
        collectionData: _latestCollectionData[collection]!,
        intercept: intercept,
      );
    }

    return newController.stream;
  }

  //TODO docs
  void dispatchLatest({
    required DocumentReference document,
    DocumentData? Function(DocumentData? data)? interceptDocument,
    CollectionData Function(CollectionData collectionData)? interceptCollection,
  }) {
    debugPrint(
        "[${document.id}] dispatching latest document and collections for document");

    _dispatchDocument(
      document: document,
      data: _latestDocumentData[document],
      intercept: interceptDocument,
    );

    //Also dispatch latestCollection data if the parent of the document is streamed
    var parentCollection = document.parent();
    var latestCollectionData = _latestCollectionData[parentCollection];
    if (parentCollection != null && latestCollectionData != null) {
      _dispatchCollection(
        collection: parentCollection,
        collectionData: latestCollectionData,
        intercept: interceptCollection,
      );
    }
  }

  //TODO docs
  void _dispatchDocument({
    required DocumentReference document,
    required DocumentData? data,
    DocumentData? Function(DocumentData? data)? intercept,
  }) {
    debugPrint("[${document.id}] dispatching document: $data");

    if (intercept != null) data = intercept.call(data);

    //Add data to all available controllers
    var controllers = _documentStreams[document] ?? [];
    for (var controller in controllers) {
      if (!controller.isClosed) controller.add(data);
    }

    //If document was deleted close streams and cancel subscription
    if (data == null) {
      for (var controller in controllers) {
        controller.close();
      }

      _documentSubscriptions[document]?.cancel();
      _documentSubscriptions.remove(document);
    }
  }

  //TODO docs
  void _dispatchCollection({
    required CollectionReference collection,
    required CollectionData collectionData,
    CollectionData Function(CollectionData collectionData)? intercept,
  }) {
    debugPrint("[${collection.id}] dispatching collection: $collectionData");

    if (intercept != null) collectionData = intercept.call(collectionData);

    //Add data to all available controllers
    var controllers = _collectionStreams[collection] ?? [];
    for (var controller in controllers) {
      if (!controller.isClosed) controller.add(collectionData);
    }
  }

  /// Force disposes all streams of a document.
  void dispose(DocumentReference document) {
    debugPrint("[${document.id}] disposing streams for document");

    _documentSubscriptions[document]?.cancel();
    _documentStreams[document]?.forEach((element) => element.close());
    _documentStreams.remove(document);
  }
}
