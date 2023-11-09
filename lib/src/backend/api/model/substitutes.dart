/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
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

class Substitutes {
  final int timestamp;
  final List<Substitute> substitutes;

  Substitutes({required this.timestamp, required this.substitutes});

  factory Substitutes.fromJson(Map<String, dynamic> json) {
    return Substitutes(
      timestamp: json["timestamp"],
      substitutes: List<Substitute>.from(
        (json["substitutes"] as List).map(Substitute.fromJson),
      ),
    );
  }
}

class Substitute extends Comparable {
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

  dynamic toJson() => {
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

  static String lessonStart(int lesson) {
    switch (lesson) {
      case 2:
        return "8:35";
      case 3:
        return "9:40";
      case 4:
        return "10:30";
      case 5:
        return "11:30";
      case 6:
        return "12:20";
      case 7:
        return "13:00";
      case 8:
        return "13:50";
      case 9:
        return "14:40";
      case 10:
        return "15:30";
      case 11:
        return "16:20";
      case 12:
        return "17:10";
      case 13:
        return "18:00";
      default: //1
        return "7:45";
    }
  }

  static String lessonEnd(int lesson) {
    switch (lesson) {
      case 2:
        return "9:20";
      case 3:
        return "10:25";
      case 4:
        return "11:15";
      case 5:
        return "12:15";
      case 6:
        return "13:00";
      case 7:
        return "13:45";
      case 8:
        return "14:35";
      case 9:
        return "15:25";
      case 10:
        return "16:15";
      case 11:
        return "17:05";
      case 12:
        return "17:55";
      case 13:
        return "18:45";
      default: //1
        return "8:35";
    }
  }

  @override
  int compareTo(covariant Substitute other) {
    var a = this;
    var b = other;
    //compare date
    if (a.date != null && b.date != null) {
      int compare = a.date!.compareTo(b.date!);
      if (compare != 0) return compare;
    }

    //compare class
    if (a.className != null && b.className != null && a.className != b.className) {
      //Q1 Q1 => false, //Q1 E1 => true, //Q1 Q1Q3 => true

      var aClassName = a.className!, bClassName = b.className!;
      var aFirst = aClassName[0], bFirst = bClassName[0];
      bool aNum = aFirst.isNumeric, bNum = bFirst.isNumeric;

      if (aNum && bNum) {
        //5a 8c => true, //Q1 5c => false, //Q1 E1 => false

        if (aFirst != bFirst) {
          //8a 5c => true, //9ac 6d => true

          var aSecond = aClassName[1], bSecond = bClassName[1];
          bool aNum = aSecond.isNumeric, bNum = bSecond.isNumeric;
          if (aNum ^ bNum) {
            return aNum ? 1 : -1;
          } else if (aNum && bNum) {
            return int.parse(aFirst + aSecond).compareTo(int.parse(bFirst + bSecond));
          } else {
            return int.parse(aFirst).compareTo(int.parse(bFirst));
          }
        } else {
          //5a 5b => true, //5a 5abc => true

          if (aClassName.length < bClassName.length) {
            //5c 5abc => true

            return -1;
          } else if (aClassName.length > bClassName.length) {
            //5abc 5c => true

            return 1;
          } else {
            //5c 5b => true, //7c 7a => true, //9abc 9ade => true

            int aVal = 0, bVal = 0;
            for (var rune in aClassName.runes) {
              aVal += rune;
            }
            for (var rune in bClassName.runes) {
              bVal += rune;
            }

            return aVal.compareTo(bVal);
          }
        }
      } else if (!aNum && !bNum) {
        //Q1 5c => false, //Q1 E1 => true

        if (aFirst != bFirst) {
          //Q1 E1 => true, //E1 Q1 => true, //Q1 Q3 => false

          return aFirst == "Q" ? 1 : -1;
          //Q1 E1 => true -> 1
          //E1 Q1 => false -> -1
        } else {
          //Q1 Q3 => true, //Q1 Q1Q3 => true, //E1Q1Q3 E1 => true

          if (aClassName.length < bClassName.length) {
            //Q1 Q1Q3 => true

            return 1;
          } else if (aClassName.length > bClassName.length) {
            //E1Q1Q3 E1 => true

            return -1;
          } else {
            //Q1 Q3 => true, //E1 E2 => true, //Q1Q2 Q1Q2 => true, //Q1Q2 Q2Q4 => true
            int aVal = 0, bVal = 0;
            for (var rune in aClassName.runes) {
              aVal += rune;
            }
            for (var rune in bClassName.runes) {
              bVal += rune;
            }

            return aVal.compareTo(bVal);
          }
        }
      } else {
        //Q1 5c => true

        return aNum ? -1 : 1;
        //Q1 5c => false -> 1
        //5c Q1 => true -> -1
      }
    }

    //compare lessons
    if (a.lesson != null && b.lesson != null && a.lesson! != b.lesson!) {
      return a.lesson! > b.lesson! ? 1 : -1;
    }

    //compare type
    return b.type.priority.compareTo(a.type.priority);
  }
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
