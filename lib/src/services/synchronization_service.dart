/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/api/api_error.dart';
import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/db/db_service.dart';
import 'package:engelsburg_planer/src/backend/util/paging.dart';
import 'package:engelsburg_planer/src/utils/type_definitions.dart';

typedef Fetch<T> = FutureOr<ApiResponse<T>> Function();
typedef PagingFetch<T> = FutureOr<ApiResponse<List<T>>> Function(Paging paging);

class SyncService {
  static Promise<T> promise<T>({
    required Request request,
    required Parser<List<T>> parse,
    String? dbOrderBy,
  }) =>
      Promise<T>(fetch: () => request.api(parse), dbOrderBy: dbOrderBy);

  static PagedPromise<T> paged<T>({
    required Request Function(Paging paging) request,
    required Parser<List<T>> parse,
    required int pagingSize,
    String? dbOrderBy,
  }) =>
      PagedPromise<T>(
        pagingFetch: (paging) => request.call(paging).api(parse),
        pagingSize: pagingSize,
        dbOrderBy: dbOrderBy,
      );
}

class Promise<T> {
  /// Fetch data from api of type List<T>
  final Fetch<List<T>> fetch;

  /// Used to get data from the database in case of a timed out request.
  /// Also responsible to enable database support at all, if null nothing will be written
  /// or read from the database
  final String? dbOrderBy;

  Promise({required this.fetch, this.dbOrderBy});

  List<T>? _current;

  ApiError? _currentError;

  /// Only set if an error occurred while loading
  /// Can be also present with data if fetch timed out and database support is available.
  /// see [data]
  ApiError? get currentError => _currentError;

  /// Retrieve current data.
  ///
  /// Returning an empty list could mean:
  /// - called before load()
  /// - an error occurred while loading
  /// - fetch returned an empty list
  ///
  /// If fetch request timed out error and data will be present if db support is available.
  /// In this case data will be the one saved in the database.
  List<T> get data => List.from(_current ?? []);

  /// Start to fetch data, don't return it yet,
  /// returning future should be awaited before calling data
  Future<void> load() async {
    //Clear current data and error
    _current = null;
    _currentError = null;

    //Start and await fetch
    var response = await fetch.call();

    //If an error is present set it as current error
    if (response.errorPresent) {
      if (response.error!.isTimedOut && dbOrderBy != null) {
        //If request was timed out get saved data from db, still set error
        _current = await DatabaseService.getAll<T>(orderBy: dbOrderBy);
      }
      _currentError = response.error!;
    }

    //If data is present set current data and update database
    if (response.dataPresent) {
      var data = response.data!;

      _current = data;
      if (dbOrderBy != null) await _updateDatabase(data);
    }
  }

  /// Updates the database with new items,
  Future<void> _updateDatabase(List<T> fetched) async {
    await DatabaseService.deleteAll<T>();
    await DatabaseService.insertAll<T>(fetched);
  }
}

class PagedPromise<T> extends Promise<T> {
  final int pagingSize;
  final PagingFetch<T> pagingFetch;

  /// State variables, current page and if no more entities are retrievable
  int _page = 0;
  bool _finished = false;

  bool get finished => _finished;

  /// Initial fetch is page 0
  PagedPromise({
    required this.pagingFetch,
    required this.pagingSize,
    String? dbOrderBy,
  }) : super(fetch: () => pagingFetch.call(Paging(0, pagingSize)), dbOrderBy: dbOrderBy);

  @override
  Future<void> load() async {
    //Set page to 0 and load
    _page = 0;
    _finished = false;

    await super.load();

    //Set finished on error to true because all data from db will be retrieved on a timeout
    if ((currentError?.isTimedOut ?? false) && dbOrderBy != null) _finished = true;
  }

  /// Returns the next page
  /// If called before load or/and get then will do that first before fetching new pages
  /// Will return empty list if all pages are loaded
  /// Make sure to check with finished to identify errors
  Future<List<T>> next() async {
    //If all pages are fetched return empty list
    if (_finished) return const [];
    //If cache is null _load wasn't executed, execute load() and return data
    if (_current == null) return load().then((value) => data);

    //Fetch new page
    _page++;
    var res = await pagingFetch.call(Paging(_page, pagingSize));
    //If error is not found there are no more pages, set flag and return empty list
    if (res.errorPresent && res.error!.isNotFound) {
      _page--;
      _finished = true;
      return const [];
    }

    //If all went correctly return fetched data and add to it to _cache
    if (res.dataPresent) {
      var data = res.data!;
      //If page has not a length of pagingSize the next request will fail
      if (data.length < pagingSize) _finished = true;

      _current!.addAll(data);
      if (dbOrderBy != null) DatabaseService.insertAll<T>(data); //Don't await
      return data;
    }

    return const [];
  }
}
