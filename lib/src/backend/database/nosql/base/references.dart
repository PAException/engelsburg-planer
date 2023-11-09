/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:flutter/foundation.dart';

typedef Parser<T> = T Function(Map<String, dynamic> json);

//TODO add to T an extends to a class that must implement toJson()??
// ===> no NoSuchMethod try-catch's
/// Object that refers to something with a blueprint how to build it.
@immutable
abstract class Reference<T> {
  /// Absolute path to the object.
  final String path;

  /// How to parse that object from plain json.
  final Parser<T> parser;

  const Reference(this.path, this.parser) : assert(path != "");

  /// Equals the last element of the path.
  String get id => path.split("/").last;

  @override
  String toString() => 'Reference{path: $path}';

  @override
  bool operator ==(Object other) => other is Reference && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// Same as Reference<T>, but only to documents.
@immutable
class DocumentReference<T> extends Reference<T> {
  const DocumentReference(super.path, super.parser);

  /// Helper function to switch between collections and documents.
  CollectionReference<D> collection<D>(String name, Parser<D> parser) =>
      CollectionReference<D>("$path/$name", parser);

  /// Get the corresponding parent of this document.
  CollectionReference<T>? parent() {
    int lastIndex = path.lastIndexOf("/");
    if (lastIndex <= 1) return null;

    return CollectionReference<T>(
      path.substring(0, lastIndex),
      parser,
    );
  }

  /// Makes the reference concrete, links a storage to the reference.
  @nonVirtual
  Document<T> storage(Storage storage) => Document<T>.ref(storage, this);
}

/// Same as Reference<T>, but only to collections.
/// The parser only refers to the documents within that collection.
@immutable
class CollectionReference<T> extends Reference<T> {
  const CollectionReference(super.path, super.parser);

  /// Helper function to switch between collections and documents.
  DocumentReference<T> doc(String name) =>
      DocumentReference<T>("$path/$name", parser);

  /// Get the corresponding parent of this collection.
  DocumentReference<D> parent<D>(Parser<D> parser) => DocumentReference<D>(
    path.substring(0, path.lastIndexOf("/")),
    parser,
  );

  /// Makes the reference concrete, links a storage to the reference.
  @nonVirtual
  Collection<T> storage(Storage storage) => Collection<T>.ref(storage, this);
}
