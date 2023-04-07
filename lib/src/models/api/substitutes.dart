/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

final DateFormat _format = DateFormat("yyyy-MM-dd");

enum SubstituteType {
  canceled, //Entfall
  independentWork, //eigenv. Arb.
  substitute, //Vertretung
  roomSubstitute, //Raum-Vtr.
  care, //Betreuung
}

class Substitute {
  final DateTime? date;
  final String? className;
  final int? lesson;
  final String? subject;
  final String? substituteTeacher;
  final String? teacher;
  final SubstituteType type;
  final String? substituteOf;
  final String? room;
  final String? text;

  Substitute({
    this.date,
    this.className,
    this.lesson,
    this.subject,
    this.substituteTeacher,
    this.teacher,
    required this.type,
    this.substituteOf,
    this.room,
    this.text,
  });

  static List<Substitute> fromSubstitutes(dynamic json) =>
      List<Substitute>.from((json is List ? json : json["substitutes"]).map(Substitute.fromJson));

  factory Substitute.fromJson(dynamic json) => Substitute(
        date: DateTime.parse(json["date"]),
        className: json["className"],
        lesson: json["lesson"] is String ? int.parse(json["lesson"]) : json["lesson"],
        subject: json["subject"],
        substituteTeacher: json["substituteTeacher"],
        teacher: json["teacher"],
        type: SubstituteTypeExt.parse(json['type']),
        substituteOf: json['substituteOf'],
        room: json['room'],
        text: json['text'],
      );

  dynamic toMap() => {
        "date": _format.format(date!),
        "className": className,
        "lesson": lesson,
        "subject": subject,
        "substituteTeacher": substituteTeacher,
        "teacher": teacher,
        "type": type.value,
        "substituteOf": substituteOf,
        "room": room,
        "text": text,
      };
}

class SubstituteMessage {
  SubstituteMessage({
    this.date,
    this.absenceTeachers,
    this.absenceClasses,
    this.affectedClasses,
    this.affectedRooms,
    this.blockedRooms,
    this.messages,
  });

  final DateTime? date;
  final String? absenceTeachers;
  final String? absenceClasses;
  final String? affectedClasses;
  final String? affectedRooms;
  final String? blockedRooms;
  final String? messages;

  static List<SubstituteMessage> fromSubstituteMessages(dynamic json) =>
      List<SubstituteMessage>.from(
          (json is List ? json : json["substituteMessages"]).map(SubstituteMessage.fromJson));

  factory SubstituteMessage.fromJson(dynamic json) => SubstituteMessage(
        date: DateTime.parse(json["date"]),
        absenceTeachers: json["absenceTeachers"],
        absenceClasses: json["absenceClasses"],
        affectedClasses: json["affectedClasses"],
        affectedRooms: json["affectedRooms"],
        blockedRooms: json["blockedRooms"],
        messages: json['messages'],
      );

  dynamic toJson() => {
        "date": _format.format(date!),
        "absenceTeachers": absenceTeachers,
        "absenceClasses": absenceClasses,
        "affectedClasses": affectedClasses,
        "affectedRooms": affectedRooms,
        "blockedRooms": blockedRooms,
        "messages": messages,
      };
}

extension SubstituteTypeExt on SubstituteType {
  String name(BuildContext context) {
    switch (this) {
      case SubstituteType.canceled:
        return context.l10n.substituteTypeCanceled;
      case SubstituteType.independentWork:
        return context.l10n.substituteTypeIndependentWork;
      case SubstituteType.roomSubstitute:
        return context.l10n.substituteTypeRoomSubstitute;
      case SubstituteType.care:
        return context.l10n.substituteTypeCare;
      case SubstituteType.substitute:
        return context.l10n.substituteTypeSubstitute;
    }
  }

  static SubstituteType parse(String toParse) {
    switch (toParse) {
      case "Entfall":
        return SubstituteType.canceled;
      case "eigenv. Arb.":
        return SubstituteType.independentWork;
      case "Raum-Vtr.":
        return SubstituteType.roomSubstitute;
      case "Betreuung":
        return SubstituteType.care;
      default:
        return SubstituteType.substitute;
    }
  }

  String get value {
    switch (this) {
      case SubstituteType.canceled:
        return "Entfall";
      case SubstituteType.independentWork:
        return "eigenv. Arb.";
      case SubstituteType.roomSubstitute:
        return "Raum-Vtr.";
      case SubstituteType.care:
        return "Betreuung";
      case SubstituteType.substitute:
        return "Vertretung";
    }
  }

  int get priority {
    switch (this) {
      case SubstituteType.canceled:
        return 4;
      case SubstituteType.independentWork:
        return 3;
      case SubstituteType.care:
        return 2;
      case SubstituteType.substitute:
        return 1;
      case SubstituteType.roomSubstitute:
        return 0;
    }
  }
}
