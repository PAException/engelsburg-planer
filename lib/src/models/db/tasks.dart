/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';

class Tasks {
  Tasks();

  static DocumentReference<Tasks> ref() =>
      const DocumentReference<Tasks>("tasks", Tasks.fromJson);

  static CollectionReference<Task> entries() =>
      ref().collection("entries", Task.fromJson);

  factory Tasks.fromJson(Map<String, dynamic> json) => Tasks();

  Map<String, dynamic> toJson() => {};
}

class Task {
  String title;
  DateTime created;
  DateTime? due;
  DocumentReference<Subject>? subject;
  String? content;
  bool done;

  Task({
    required this.title,
    required this.created,
    this.due,
    this.subject,
    this.content,
    this.done = false,
  });

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        title: json["title"],
        created: DateTime.fromMillisecondsSinceEpoch(json["created"]),
        due: json["due"] == null ? null : DateTime.fromMillisecondsSinceEpoch(json["due"]),
        subject: json["subject"] == null ? null : Subjects.entries().doc(json["subject"]),
        content: json["content"],
        done: json["done"],
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "created": created.millisecondsSinceEpoch,
        "due": due?.millisecondsSinceEpoch,
        "subject": subject?.id,
        "content": content,
        "done": done,
      };
}
