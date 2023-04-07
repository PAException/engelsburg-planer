/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class UserState extends ChangeNotifier {
  final FirebaseAuth instance = FirebaseAuth.instance;
  List<String>? _signInMethods;

  UserState() {
    instance.userChanges().listen((event) {
      if (loggedIn) {
        instance.fetchSignInMethodsForEmail(email!).then((value) {
          _signInMethods = value;
          notifyListeners();
        });
        notifyListeners();
      }
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

  /// Get login via. Safe to use if loggedIn == true.
  List<UserInfo>? getOAuths() => instance.currentUser?.providerData;

  UserInfo? oauth(String providerId) =>
      getOAuths()?.firstNullableWhere((e) => e.providerId == providerId);

  /// Get refresh token. Returns false if loggedIn == false otherwise if user is verified.
  bool get isVerified => instance.currentUser?.emailVerified ?? false;

  bool hasOAuth(String providerId) =>
      getOAuths()?.any((element) => element.providerId == providerId) ?? false;

  List<String>? get signInMethods => _signInMethods;

  bool get hasPassword => signInMethods?.contains("password") ?? false;
}
