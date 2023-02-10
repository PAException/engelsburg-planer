/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/util/paging.dart';
import 'package:engelsburg_planer/src/backend/util/query.dart';
import 'package:engelsburg_planer/src/models/api/dto/create_semester_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/create_subject_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/reset_password_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/sign_in_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/sign_up_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/update_semester_request_dto.dart';
import 'package:engelsburg_planer/src/models/api/dto/update_subject_request_dto.dart';

///
/// Host to send requests to
///
class Host {
  static const bool enforceHttpForDebug = true;

  //static String get api => "engelsburg-api.de";
  static String get api => "10.0.2.2";
}

///
/// Path of requests
///
class Path {
  static String get article => "article";

  static String get articleSave => "$article/save";

  static String get event => "event";

  static String get cafeteria => "cafeteria";

  static String get solarSystem => "solar_system";

  static String get substitute => "substitute";

  static String get substituteMessage => "$substitute/message";

  static String get subject => "subject";

  static String get semester => "semester";

  static String get baseSubjects => "$subject/base";

  static String get timetable => "timetable";

  static UserPath get user => const UserPath();

  static AuthPath get auth => const AuthPath();
}

class UserPath {
  const UserPath();

  String get path => "user";

  String get data => "$path/data";

  String get notification => "$path/notification";

  String get notificationDevice => "$notificationDevice/device";
}

class AuthPath {
  const AuthPath();

  String get path => "auth";

  String get signUp => "$path/signup";

  String get refresh => "$path/refresh";

  String get signIn => "$path/login";

  String get verify => "$path/verify";

  String get resetPassword => "$path/reset_password";

  String get requestResetPassword => "$path/request_reset_password";

  String get scope => "$path/scope";

  String get oauth => "$path/oauth";
}

///
///
/// Requests
///
///

///
/// Articles
///
RequestBuilder getArticles({int? date, Paging paging = const Paging(0, 20)}) => Request.builder()
    .https
    .api
    .get
    .path(Path.article)
    .params(Query.paging(paging) + Query.date(date))
    .cache("articles");

RequestBuilder getArticle(int id) => Request.builder().https.api.get.path("${Path.article}/$id");

RequestBuilder getChangedArticles(List<String> hashes) =>
    Request.builder().https.api.patch.path(Path.article).jsonBody({"hashes": hashes});

/// Save article
RequestBuilder _saveArticle(int articleId) =>
    Request.builder().https.api.authenticated.path("${Path.articleSave}/$articleId");

RequestBuilder saveArticle(int articleId, bool set) =>
    set ? _saveArticle(articleId).patch : _saveArticle(articleId).delete;

RequestBuilder getSavedArticles() =>
    Request.builder().https.api.authenticated.get.path(Path.articleSave).cache("article_save");

///
/// Auth
///
RequestBuilder signUp(SignUpRequestDTO dto) =>
    Request.builder().https.api.post.path(Path.auth.signUp).jsonBody(dto);

RequestBuilder signIn(SignInRequestDTO dto) =>
    Request.builder().https.api.post.path(Path.auth.signIn).jsonBody(dto);

RequestBuilder refreshTokens(String refreshToken) =>
    Request.builder().https.api.get.path(Path.auth.refresh).param("refreshToken", refreshToken);

RequestBuilder requestScope(Map<String, String> scopesAndVerifications) => Request.builder()
    .https
    .api
    .authenticated
    .patch
    .path(Path.auth.scope)
    .params(Query(scopesAndVerifications));

RequestBuilder verifyEmail(String token) => Request.builder()
    .https
    .api
    .patch
    .authenticated
    .path(Path.auth.verify)
    .params(Query.token(token));

RequestBuilder requestPasswordReset(String email) => Request.builder()
    .https
    .api
    .post
    .path(Path.auth.requestResetPassword)
    .params(Query.email(email));

RequestBuilder requestPasswordSet(String email) => requestPasswordReset(email).authenticated;

RequestBuilder resetPassword(ResetPasswordRequestDTO dto) =>
    Request.builder().https.api.patch.path(Path.auth.resetPassword).jsonBody(dto);

///
/// OAuth
///
RequestBuilder signUpOAuth(String service, String accessToken) => Request.builder()
    .https
    .api
    .post
    .path("${Path.auth.oauth}/$service")
    .params(Query.accessToken(accessToken));

RequestBuilder signInOAuth(String service, String accessToken) => Request.builder()
    .https
    .api
    .get
    .path("${Path.auth.oauth}/$service")
    .params(Query.accessToken(accessToken));

RequestBuilder connectOAuth(String service, String accessToken) => Request.builder()
    .https
    .api
    .patch
    .authenticated
    .path("${Path.auth.oauth}/$service")
    .params(Query.accessToken(accessToken));

RequestBuilder disconnectOAuth(String service) =>
    Request.builder().https.api.delete.authenticated.path("${Path.auth.oauth}/$service");

///
/// Substitutes
///
RequestBuilder getSubstitutes({String? className, String? teacher, String? substituteTeacher}) =>
    Request.builder()
        .https
        .api
        .get
        .authenticated
        .path(Path.substitute)
        .params(Query.substitutes(
            className: className, teacher: teacher, substituteTeacher: substituteTeacher))
        .cache("substitutes");

RequestBuilder getSubstituteMessages() => Request.builder()
    .https
    .api
    .get
    .authenticated
    .path(Path.substituteMessage)
    .cache("substitute_messages");

///
/// User
///
RequestBuilder getUserData() =>
    Request.builder().https.api.get.authenticated.path(Path.user.data).cache("user_data");

RequestBuilder deleteUser() =>
    Request.builder().https.api.delete.authenticated.path(Path.user.data);

/// Notification
RequestBuilder _setNotificationDevice(String token) => Request.builder()
    .https
    .api
    .authenticated
    .path(Path.user.notificationDevice)
    .params(Query.token(token));

RequestBuilder setNotificationDevice(String token, bool enable) =>
    enable ? _setNotificationDevice(token).post : _setNotificationDevice(token).delete;

///
/// Other
///
RequestBuilder getEvents() => Request.builder().https.api.get.path(Path.event).cache("event");

RequestBuilder getCafeteria() =>
    Request.builder().https.api.get.path(Path.cafeteria).cache("cafeteria");

RequestBuilder getSolarSystem() =>
    Request.builder().https.api.get.path(Path.solarSystem).cache("solar_system");

///
/// Timetable
///
RequestBuilder getTimetable(int? day, int? lesson) => Request.builder()
    .https
    .api
    .get
    .authenticated
    .path(Path.timetable)
    .params(Query.timetable(day, lesson))
    .cache("timetable-$day-$lesson");

///
/// Subjects
///
RequestBuilder createSubject(CreateSubjectRequestDTO dto) =>
    Request.builder().https.api.authenticated.post.path(Path.subject).jsonBody(dto);

RequestBuilder updateSubject(UpdateSubjectRequestDTO dto) =>
    Request.builder().https.api.authenticated.patch.path(Path.semester).jsonBody(dto);

RequestBuilder getSubject(int subjectId) =>
    Request.builder().https.api.authenticated.get.path("${Path.semester}/$subjectId");

RequestBuilder getAllSubjects() =>
    Request.builder().https.api.authenticated.get.path(Path.subject).cache("subjects");

RequestBuilder deleteSubject(int subjectId) =>
    Request.builder().https.api.authenticated.delete.path(Path.subject);

/// BaseSubject
RequestBuilder getBaseSubjects() =>
    Request.builder().https.api.get.path(Path.baseSubjects).cache("base_subjects");

///
/// Semesters
///
RequestBuilder createSemester(CreateSemesterRequestDTO dto) =>
    Request.builder().https.api.authenticated.post.path(Path.semester).jsonBody(dto);

RequestBuilder updateSemester(UpdateSemesterRequestDTO dto) =>
    Request.builder().https.api.authenticated.patch.path(Path.semester).jsonBody(dto);

RequestBuilder getSemester(int semesterId) =>
    Request.builder().https.api.authenticated.get.path("${Path.semester}/$semesterId");

RequestBuilder getAllSemester() =>
    Request.builder().https.api.authenticated.get.path(Path.semester).cache("semester");

RequestBuilder deleteSemester(int semesterId) =>
    Request.builder().https.api.authenticated.delete.path("${Path.semester}/$semesterId");
