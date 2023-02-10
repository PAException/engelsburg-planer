/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/db/table.dart';
import 'package:engelsburg_planer/src/models/api/article.dart';
import 'package:engelsburg_planer/src/models/api/subject.dart';
import 'package:engelsburg_planer/src/models/api/tasks.dart';
import 'package:engelsburg_planer/src/models/api/timetable.dart';

Table<Article> article = Table<Article>(
  "article",
  "articleId INTEGER PRIMARY KEY, date INTEGER, link TEXT, title TEXT, content TEXT, contentHash TEXT, mediaUrl TEXT, blurHash TEXT",
  (t) => t.toJson(),
  Article.fromJson,
);

Table<TimetableEntry> timetable = Table<TimetableEntry>(
  "timetable",
  "day INTEGER, lesson INTEGER, teacher VARCHAR(20), className VARCHAR(20), room VARCHAR(20), subjectId INTEGER, PRIMARY KEY (day, lesson)",
  (t) => t.toJson(),
  TimetableEntry.fromJson,
);

Table<Task> task = Table<Task>(
  "tasks",
  "taskId INTEGER PRIMARY KEY, title TEXT, created INTEGER, due INTEGER, subjectId INTEGER, content TEXT, done INTEGER",
  (t) => t.toJson(),
  Task.fromJson,
);

Table<Subject> subject = Table<Subject>(
  "subjects",
  "subjectId INTEGER PRIMARY KEY, baseSubject VARCHAR(20), customName VARCHAR(50), color VARCHAR(20), advancedCourse INTEGER",
  (t) => t.toJson(),
  Subject.fromJson,
);
