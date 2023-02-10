/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/backend/api/api_response.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart' as requests;
import 'package:engelsburg_planer/src/backend/db/db_service.dart';
import 'package:engelsburg_planer/src/models/api/dto/create_subject_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/subject.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';

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

  final List<Subject> _subjects = [];

  @override
  Future<void> setup() async {
    if (globalContext().loggedIn) {
      requests.getAllSubjects().build().api(Subject.fromSubjects).then((res) async {
        if (res.dataPresent) {
          var data = res.data!;

          //Add fetched data to memory
          //Clear db and write fetched data
          _subjects.addAll(data);
          await DatabaseService.deleteAll<Subject>();
          await DatabaseService.insertAll<Subject>(data);
        } else {
          //TODO couldn't get subjects

          //Get all stored subjects from database
          DatabaseService.getAll<Subject>().then((value) => _subjects.addAll(value));
        }
      });
    }

    //Try to get all baseSubjects from api
    requests.getBaseSubjects().build().api(BaseSubject.fromBaseSubjects).then((res) {
      if (res.dataPresent) {
        _baseSubjects.clear();
        for (var baseSubject in res.data!) {
          _baseSubjects[baseSubject.name] = baseSubject.group;
        }
      } else {
        //TODO couldn't get baseSubjects
      }
    });
  }

  Future<Subject?> addSubject(CreateSubjectRequestDTO dto) async {
    if (globalContext().loggedIn) {
      //Create on api first
      var res = await requests.createSubject(dto).build().api(Subject.fromJson);
      if (res.dataPresent) {
        var data = res.data!;

        //If confirmed insert the response with a valid subjectId to into the db and memory
        _subjects.add(data);
        DatabaseService.insert<Subject>(data);

        return data;
      } else {
        //TODO couldn't create subject
      }
    } else {
      Subject subject = dto.toSubject();

      //If not logged in only create in db and memory
      int? id = await DatabaseService.insert<Subject>(subject);
      if (id != null && id != 0) {
        subject.subjectId = id;
        _subjects.add(subject);

        return subject;
      }
    }
    return null;
  }

  //Future<Subject?> updateSubject(UpdateSubjectRequestDTO dto) {}

  Subject getSubject(int subjectId) =>
      _subjects.firstWhere((element) => element.subjectId == subjectId);

  List<Subject> getAllSubjects() => List.of(_subjects);

  Future<void> removeSubject(int subjectId) async {
    if (globalContext().loggedIn) {
      //Delete on api first
      var res = await requests.deleteSubject(subjectId).build().api(ignore);
      if (res.errorNotPresent || (res.error?.isNotFound ?? false)) {
        //If confirmed delete in memory and database
        _subjects.removeWhere((element) => element.subjectId == subjectId);
        await DatabaseService.delete(where: "subjectId=?", whereArgs: [subjectId]);
      } else {
        //TODO couldn't delete subject
      }
    } else {
      //If not logged in delete in memory and database only
      _subjects.removeWhere((element) => element.subjectId == subjectId);
      await DatabaseService.delete(where: "subjectId=?", whereArgs: [subjectId]);
    }
  }

  Future<ApiResponse<List<Subject>>> getEditableSubjectList() async {
    return ApiResponse(
        null,
        null,
        _baseSubjects.keys.map((e) => Subject(baseSubject: e)).map(
          (e) {
            return _subjects.firstWhere(
              (subject) => subject.baseSubject == e.baseSubject,
              orElse: () => e,
            );
          },
        ).toList()
          ..sort());
  }

  BaseSubject getBaseSubject(Subject subject) => BaseSubject(
        name: subject.baseSubject,
        group: _baseSubjects[subject.baseSubject] ?? "OTHER",
      );
}
