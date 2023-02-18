/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/models/api/subject.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';

class SubjectService extends DataService {
  ///Name and group
  final Map<String, String> _baseSubjects = {
    "biology": "SCIENTIFIC",
    "chemistry": "SCIENTIFIC",
    "informatics": "SCIENTIFIC",
    "math": "SCIENTIFIC",
    "physics": "SCIENTIFIC",
    "ethics": "SOCIAL_SCIENTIFIC",
    "geography": "SOCIAL_SCIENTIFIC",
    "history": "SOCIAL_SCIENTIFIC",
    "philosophy": "SOCIAL_SCIENTIFIC",
    "psychology": "SOCIAL_SCIENTIFIC",
    "religion": "SOCIAL_SCIENTIFIC",
    "economics": "SOCIAL_SCIENTIFIC",
    "german": "LINGUISTICALLY_LITERARY",
    "art": "LINGUISTICALLY_LITERARY",
    "music": "LINGUISTICALLY_LITERARY",
    "english": "FOREIGN_LINGUISTICALLY",
    "french": "FOREIGN_LINGUISTICALLY",
    "greek": "FOREIGN_LINGUISTICALLY",
    "italian": "FOREIGN_LINGUISTICALLY",
    "latin": "FOREIGN_LINGUISTICALLY",
    "spanish": "FOREIGN_LINGUISTICALLY",
    "sport": "OTHER",
  };

  final Map<String, Subject> _subjects = {};

  @override
  Future<void> setup() async {
    var items = await Subjects.online.subjects.items;
    var entries = await items.asyncMap((e) async => MapEntry(e.id, await e.load(true)));
    _subjects.addEntries(entries);

    Subjects.online.subjects.snapshots.listen((event) async {
      _subjects.clear();
      _subjects.addAll(event);
    });
  }

  void addSubject(Subject subject) => Subjects.online.subjects.add(subject);

  Future<void> removeSubject(String subjectId) => Subjects.online.subjects[subjectId].delete();

  BaseSubject getBaseSubject(Subject subject) => BaseSubject(
        name: subject.baseSubject,
        group: _baseSubjects[subject.baseSubject] ?? "OTHER",
      );
}
