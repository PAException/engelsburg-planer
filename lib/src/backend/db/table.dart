/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';

typedef Serializer<T> = Json Function(T t);
typedef Deserializer<T> = T Function(Json map);

/// Provides information how to store structural data.
///
/// Create function of table of type in tables.dart to get that table. To use it with
/// the DatabaseService
class Table<T> {
  final String name;
  final String structure;
  final Serializer<T> serialize;
  final Deserializer<T> deserialize;

  const Table(this.name, this.structure, this.serialize, this.deserialize);
}

Table<Article> article = Table<Article>(
  "article",
  "articleId INTEGER PRIMARY KEY, date INTEGER, link TEXT, title TEXT, content TEXT, contentHash TEXT, mediaUrl TEXT, blurHash TEXT",
  (t) => t.toJson(),
  Article.fromJson,
);
