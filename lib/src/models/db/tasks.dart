/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:engelsburg_planer/main.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Tasks {
  Tasks();

  static TasksSchema get([bool online = storeOnline]) => online ? TasksOnline() : TasksOffline();

  factory Tasks.fromJson(Map<String, dynamic> json) {
    return Tasks();
  }

  Map<String, dynamic> toJson() {
    return {};
  }
}

abstract class TasksSchema extends Document<Tasks> {
  Collection<Document<Task>, Task> get entries;
}

class TasksOnline extends OnlineDocument<Tasks> implements TasksSchema {
  TasksOnline() : super(documentReference: doc, fromJson: Tasks.fromJson);

  static DocumentReference<Map<String, dynamic>> doc() =>
      FirebaseFirestore.instance.collection("tasks").doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  Collection<Document<Task>, Task> get entries => OnlineCollection<OnlineDocument<Task>, Task>(
        collection: () => document.collection("entries"),
        buildType: (doc) => OnlineDocument(
          documentReference: () => doc,
          fromJson: Task.fromJson,
        ),
      );
}

class TasksOffline extends OfflineDocument<Tasks> implements TasksSchema {
  TasksOffline() : super(key: "tasks", fromJson: Tasks.fromJson);

  @override
  Collection<Document<Task>, Task> get entries => OfflineCollection<OfflineDocument<Task>, Task>(
        parent: this,
        collection: "entries",
        buildType: (id, parent) => OfflineDocument(
          parent: parent,
          key: id,
          fromJson: Task.fromJson,
        ),
      );
}

class Task {
  String title;
  DateTime created;
  DateTime? due;
  Document<Subject>? subject;
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

  factory Task.fromJson(dynamic json) => Task(
        title: json["title"],
        created: DateTime.fromMillisecondsSinceEpoch(json["created"]),
        due: json["due"] == null ? null : DateTime.fromMillisecondsSinceEpoch(json["due"]),
        subject: json["subject"] == null ? null : Subjects.get().entries[json["subject"]],
        content: json["content"],
        done: json["done"],
      );

  dynamic toJson() => {
        "title": title,
        "created": created.millisecondsSinceEpoch,
        "due": due?.millisecondsSinceEpoch,
        "subject": subject?.id,
        "content": content,
        "done": done,
      };
}
