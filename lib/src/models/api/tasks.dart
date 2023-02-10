/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

class Task {
  final int taskId;
  String? title;
  int? created;
  int? due;
  int? subjectId;
  String? content;
  bool done;

  Task({
    required this.taskId,
    this.title,
    this.created,
    this.due,
    this.subjectId,
    this.content,
    this.done = false,
  });

  static List<Task> fromTasks(dynamic json) => List<Task>.from(json["tasks"].map(Task.fromJson));

  factory Task.fromJson(dynamic json) => Task(
        taskId: json["taskId"],
        title: json["title"],
        created: json["created"],
        due: json["due"],
        subjectId: json["subjectId"],
        content: json["content"],
        done: json["done"] == 1,
      );

  dynamic toJson() => {
        "taskId": taskId,
        "title": title,
        "created": created,
        "due": due,
        "subjectId": subjectId,
        "content": content,
        "done": done ? 1 : 0,
      };
}
