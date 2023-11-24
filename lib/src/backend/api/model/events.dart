/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

class Event {
  final DateTime? date;
  final String? title;

  Event({
    this.date,
    this.title,
  });

  static List<Event> fromEvents(dynamic json) {
    if (json is Map) json = json["events"];

    return json.map<Event>((e) => Event.fromJson(e)).toList();
  }

  factory Event.fromJson(dynamic json) => Event(
        date: DateTime.tryParse(json['date']),
        title: json['title'],
      );

  dynamic toJson() => {
        'date': date?.toIso8601String(),
        'title': title,
      };
}
