/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/db/table.dart';
import 'package:engelsburg_planer/src/backend/util/paging.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _db;
  static Set<Table>? _tables;

  /// Get table by type
  static Table<T> getTable<T>() {
    //Throw error if _tables is null
    if (_tables == null) throw StateError("Tables are not initialized!");
    if (T == dynamic) throw StateError("dynamic is not a valid type!");

    //Filter _tables for requested type, throw error if none found
    var table = _tables!.whereType<Table<T>>().toSet();
    if (table.isEmpty) throw ArgumentError("$T has no referring table!");

    return table.first;
  }

  /// Init db service
  static Future<void> initialize() async {
    //Init tables
    _tables = {article};

    //Open database
    _db = await openDatabase(
      join(await getDatabasesPath(), 'data.db'),
      version: 1,
    );

    //Create tables if not existing
    //Parse sql to create tables
    Batch batch = _db!.batch();
    for (var table in _tables!) {
      batch.execute("CREATE TABLE IF NOT EXISTS ${table.name}(${table.structure})");
    }

    //Execute parsed sql
    await batch.commit();
  }

  /// Insert a model
  static Future<int?> insert<T>(
    T model, {
    ConflictAlgorithm? conflictAlgorithm = ConflictAlgorithm.ignore,
  }) async {
    var table = getTable<T>();

    return await _db?.insert(
      table.name,
      table.serialize.call(model),
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Insert many model
  static Future<List<Object?>> insertAll<T>(
    List<T> models, {
    ConflictAlgorithm? conflictAlgorithm = ConflictAlgorithm.ignore,
  }) async {
    var batch = _db!.batch();
    var table = getTable<T>();

    for (var model in models) {
      batch.insert(
        table.name,
        table.serialize.call(model),
        conflictAlgorithm: conflictAlgorithm,
      );
    }
    return batch.commit();
  }

  /// Update a model
  static Future<void> update<T>(
    T model, {
    String? where,
    List<Object>? whereArgs,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    var table = getTable<T>();

    await _db?.update(
      table.name,
      table.serialize.call(model),
      where: where,
      whereArgs: whereArgs,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  /// Update many models
  static Future<void> updateAll<T>(
    List<T> models, {
    String? where,
    List<PropertySupplier<dynamic, T>>? whereArgs,
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace,
  }) async {
    var batch = _db!.batch();
    var table = getTable<T>();

    for (var model in models) {
      batch.update(
        table.name,
        table.serialize.call(model),
        where: where,
        whereArgs: whereArgs?.map((e) => e.call(model)).toList(),
        conflictAlgorithm: conflictAlgorithm,
      );
    }
    batch.commit();
  }

  /// Get a model
  static Future<T?> get<T>({
    String? orderBy,
    String? where,
    List<Object>? whereArgs,
  }) async {
    final ret = await getAll<T>(
      paging: const Paging(0, 1),
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
    );

    return ret.isEmpty ? null : ret.first;
  }

  /// Get many models
  static Future<List<T>> getAll<T>({
    Paging? paging,
    String? orderBy,
    String? where,
    List<Object>? whereArgs,
  }) async {
    var table = getTable<T>();

    final ret = await _db?.query(
      table.name,
      limit: paging?.size,
      offset: paging == null ? null : paging.page * paging.size,
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
    );
    if (ret == null || ret.isEmpty) return [];

    return ret.map(table.deserialize.call).toList();
  }

  /// Get specified models by batch. Queries are executed as the length of whereArgs. In every
  /// iteration whereArgs is applied to where.
  static Future<List<T>> getBatched<T>({
    Paging? paging,
    String? orderBy,
    required String where,
    required List<List<Object>> whereArgs,
  }) async {
    var batch = _db!.batch();
    var table = getTable<T>();

    for (var args in whereArgs) {
      batch.query(
        table.name,
        limit: paging?.size,
        offset: paging == null ? null : paging.page * paging.size,
        orderBy: orderBy,
        where: where,
        whereArgs: args,
      );
    }

    return (await batch.commit())
        .expand((e) => e as List)
        .map((e) => table.deserialize.call(e))
        .toList();
  }

  /// Deletes rows in a table by given query
  static Future<void> delete<T>({String? where, List<Object>? whereArgs}) async =>
      await _db?.delete(getTable<T>().name, where: where, whereArgs: whereArgs);

  /// Deletes all rows in a table
  static Future<void> deleteAll<T>() => delete<T>();
}
