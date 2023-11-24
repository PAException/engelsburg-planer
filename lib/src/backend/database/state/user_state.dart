/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/collection.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/references.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/implementations/firestore_storage.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/implementations/local_storage.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/intercepted_storage.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/interceptor/prefix_interceptor.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/storage/storage.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// Keeps track of the account of the user.
/// All information should be treated as null if [loggedIn] is false.
class UserState extends ChangeNotifier {
  final FirebaseAuth instance = FirebaseAuth.instance;
  List<String>? _signInMethods;

  UserState() {
    Crashlytics.set("user_state", this);
    instance.userChanges().listen((event) {
      if (loggedIn) {
        instance.fetchSignInMethodsForEmail(email!).then((value) {
          _signInMethods = value;
          notifyListeners();
        });
        notifyListeners();
      }
      Crashlytics.set("user_state", this);
    });
  }

  /// Check if any authentication information is present
  bool get loggedIn => instance.currentUser != null;

  /// Get email of user. Safe to use if loggedIn == true.
  ///
  /// Can also be null if the user's account was created via OAuth.
  String? get email => instance.currentUser?.email;

  /// Get username. Safe to use if loggedIn == true.
  String? get username => instance.currentUser?.displayName;

  /// Get refresh token. Returns false if loggedIn == false otherwise if user is verified.
  bool get isVerified => instance.currentUser?.emailVerified ?? false;

  List<String>? get signInMethods => _signInMethods;

  bool get hasPassword => signInMethods?.contains("password") ?? false;

  /// Get login via. Safe to use if loggedIn == true.
  List<UserInfo>? getOAuths() => instance.currentUser?.providerData;

  UserInfo? oauth(String providerId) =>
      getOAuths()?.firstNullableWhere((e) => e.providerId == providerId);

  bool hasOAuth(String providerId) =>
      getOAuths()?.any((element) => element.providerId == providerId) ?? false;

  Map<String, dynamic> toJson() => {
        "loggedIn": loggedIn,
        "email": email,
        "username": username,
        "verified": isVerified,
        "signInMethods": signInMethods,
        "oAuths": getOAuths()
            ?.map((oAuth) => {
                  "providerId": oAuth.providerId,
                  "uid": oAuth.uid,
                  "email": oAuth.email,
                  "displayName": oAuth.displayName,
                  "phoneNumber": oAuth.phoneNumber,
                  "photoUrl": oAuth.photoURL,
                })
            .toList(),
      };
}


final Storage _offline = LocalStorage().withInterceptors(
  [
    PrefixInterceptor.static("local"),
    GoogleAnalyticsInterceptor("local"),
  ],
);
final Storage _online = FirestoreStorage().withInterceptors(
  [
    PrefixInterceptor(() => FirebaseAuth.instance.currentUser!.uid),
    GoogleAnalyticsInterceptor("firestore"),
  ],
);

Storage chooseDefaultStorage(BuildContext context) =>
    context.read<UserState>().loggedIn ? _online : _offline;

extension DocumentExt<T> on DocumentReference<T> {
  Document<T> defaultStorage(BuildContext context) =>
      storage(chooseDefaultStorage(context));

  Document<T> get offline => storage(_offline);
  Document<T> get online => storage(_online);
}

extension CollectionExt<T> on CollectionReference<T> {
  Collection<T> defaultStorage(BuildContext context) =>
      storage(chooseDefaultStorage(context));
}
