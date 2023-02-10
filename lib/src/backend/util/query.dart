/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/util/paging.dart';

/// Utility class to handle request parameter
class Query {
  late final Map<String, dynamic> _query;

  Query(this._query);

  /// Some default queries which are often used
  factory Query.date(int? date) => Query(date != null ? {"date": date} : {});

  factory Query.email(String? email) => Query({if (email != null) "email": email});

  factory Query.accessToken(String? accessToken) =>
      Query({if (accessToken != null) "accessToken": accessToken});

  factory Query.token(String? token) => Query({if (token != null) "token": token});

  factory Query.paging(Paging? paging) =>
      Query(paging != null ? {"page": paging.page, "size": paging.size} : {});

  factory Query.substitutes({
    int? date,
    int? lesson,
    String? className,
    String? substituteTeacher,
    String? teacher,
  }) =>
      Query({
        if (date != null) "date": date,
        if (lesson != null) "lesson": lesson,
        if (className != null) "className": className,
        if (substituteTeacher != null) "substituteTeacher": substituteTeacher,
        if (teacher != null) "teacher": teacher,
      });

  factory Query.timetable(int? day, int? lesson) => Query({
        if (day != null) "day": day,
        if (lesson != null) "lesson": lesson,
      });

  /// Parse Query to actual string in request
  static String parse(Map<String, dynamic> query) {
    StringBuffer buffer = StringBuffer();
    bool started = false;

    query.forEach((key, value) {
      if (!started) {
        started = true;
        buffer.write("?");
      } else {
        buffer.write("&");
      }

      buffer.write(key);
      buffer.write("=");
      buffer.write(value);
    });

    return buffer.toString();
  }

  /// Shorthand to parse instance
  String get get => parse(_query);

  /// Several operators to make customizations more intuitive
  Query operator +(Query? other) {
    if (other == null) return this;

    _query.addAll(other._query);
    return this;
  }

  dynamic operator [](String key) => _query[key];

  operator []=(String key, dynamic value) => _query[key] = value;
}
