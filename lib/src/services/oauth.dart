/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/auth/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum OAuthType { signIn, link, unlink, reauthenticate }

extension OAuthTypeExt on OAuthType {
  /// Executes the action to the current type which should be performed.
  Future<void> action(OAuth oAuth, [VoidCallback? onSuccess]) async {
    try {
      switch (this) {
        case OAuthType.signIn:
          await oAuth._signIn();
          break;
        case OAuthType.link:
          await oAuth._link();
          break;
        case OAuthType.unlink:
          await oAuth._unlink();
          break;
        case OAuthType.reauthenticate:
          await oAuth._reauthenticate();
      }

      onSuccess?.call();
    } on FirebaseAuthException catch (e) {
      await handleErrorCode(oAuth, e);
    }
  }

  Future<void> handleErrorCode(OAuth oAuth, FirebaseAuthException error) async {
    var code = error.code;
    switch (code) {
      case "account-exists-with-different-credential":
        List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(error.email!);

        if (methods.first == "password") {
          const EmailPasswordBottomSheet().show(globalContext());
        } else {
          OAuth.fromId(methods.first)!.signIn();
        }

        FirebaseAuth.instance.currentUser!.linkWithCredential(error.credential!);
        break;
      case "provider-already-linked":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: Already linked");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "credential-already-in-use":
        //TODO handle credential-already-in-use
        break;
      case "email-already-in-use":
        List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(error.email!);

        if (methods.first == "password") {
          const EmailPasswordBottomSheet().show(globalContext());
        } else {
          OAuth.fromId(methods.first)!.signIn();
        }

        FirebaseAuth.instance.currentUser!.linkWithCredential(error.credential!);
        break;
      case "no-such-provider":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: Method not linked with user");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "user-aborted":
        debugPrint("INFO: OAuth[${oAuth.providerId}]: User aborted");
        break;
      case "user-disabled":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: User is disabled");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "user-not-found":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: User does not exist");
        FirebaseAuth.instance.signOut();
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "user-mismatch":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: Credential does not correspond to user");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "invalid-credential":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: Malformed or expired credential");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      case "operation-not-allowed":
        debugPrint("WARNING: OAuth[${oAuth.providerId}]: Method not supported");
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
      default:
        globalContext().showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
        break;
    }
  }
}

abstract class OAuth {
  final String providerId;

  OAuth(this.providerId);

  /// Sign in a user via OAuth.
  ///
  /// Throws FirebaseAuthException when failing.
  ///
  /// Possible error codes are:
  /// - account-exists-with-different-credential: Thrown if there already exists an account with the
  ///   email address asserted by the credential. Resolve this by calling fetchSignInMethodsForEmail
  ///   and then asking the user to sign in using one of the returned providers. Once the user is
  ///   signed in, the original credential can be linked to the user with linkWithCredential.
  /// - invalid-credential: Thrown if the credential is malformed or has expired.
  /// - operation-not-allowed: Thrown if the type of account corresponding to the credential is not
  ///   enabled. Enable the account type in the Firebase Console, under the Auth tab.
  /// - user-disabled: Thrown if the user corresponding to the given credential has been disabled.
  /// - user-aborted: Thrown if the user aborted the authentication process.
  FutureOr<UserCredential> _signIn();

  Future<void> signIn() => OAuthType.signIn.action(this);

  /// Links an OAuth to a user.
  ///
  /// Throws FirebaseAuthException when failing.
  ///
  /// Possible error codes are:
  /// - provider-already-linked: Thrown if the provider has already been linked to the user. This
  ///   error is thrown even if this is not the same provider's account that is currently linked to
  ///   the user.
  /// - invalid-credential: Thrown if the provider's credential is not valid. This can happen if it
  ///   has already expired when calling link, or if it used invalid token(s). See the Firebase
  ///   documentation for your provider, and make sure you pass in the correct parameters to the
  ///   credential method.
  /// - credential-already-in-use: Thrown if the account corresponding to the credential already
  ///   exists among your users, or is already linked to a Firebase User. For example, this error
  ///   could be thrown if you are upgrading an anonymous user to a Google user by linking a Google
  ///   credential to it and the Google credential used is already associated with an existing
  ///   Firebase Google user. The fields email, phoneNumber, and credential (AuthCredential) may be
  ///   provided, depending on the type of credential. You can recover from this error by signing in
  ///   with credential directly via signInWithCredential. Please note, you will not recover from
  ///   this error if you're using a PhoneAuthCredential to link a provider to an account. Once an
  ///   attempt to link an account has been made, a new sms code is required to sign in the user.
  /// - email-already-in-use: Thrown if the email corresponding to the credential already exists
  ///   among your users. When thrown while linking a credential to an existing user, an email and
  ///   credential (AuthCredential) fields are also provided. You have to link the credential to the
  ///   existing user with that email if you wish to continue signing in with that credential. To do
  ///   so, call fetchSignInMethodsForEmail, sign in to email via one of the providers returned and
  ///   then User.linkWithCredential the original credential to that newly signed in user.
  /// - operation-not-allowed: Thrown if you have not enabled the provider in the Firebase Console.
  ///   Go to the Firebase Console for your project, in the Auth section and the Sign in Method tab
  ///   and configure the provider.
  /// - user-aborted: Thrown if the user aborted the authentication process.
  FutureOr<UserCredential> _link();

  Future<void> link() => OAuthType.link.action(this);

  /// Reauthenticates an user via OAuth.
  ///
  /// Throws FirebaseAuthException when failing.
  ///
  /// Possible error codes are:
  /// - user-mismatch: Thrown if the credential given does not correspond to the user.
  /// - user-not-found: Thrown if the credential given does not correspond to any existing user.
  /// - invalid-credential: Thrown if the provider's credential is not valid. This can happen if it
  ///   has already expired when calling link, or if it used invalid token(s). See the Firebase
  ///   documentation for your provider, and make sure you pass in the correct parameters to the
  ///   credential method.
  FutureOr<UserCredential> _reauthenticate();

  Future<void> reauthenticate() => OAuthType.reauthenticate.action(this);

  /// Unlinks an OAuth from an user.
  ///
  /// Throws FirebaseAuthException when failing.
  ///
  /// Possible error codes are:
  /// - no-such-provider: Thrown if the user does not have this provider linked or when the provider
  ///   ID given does not exist.
  Future<User> _unlink() => FirebaseAuth.instance.currentUser!.unlink(providerId);

  Future<void> unlink() => OAuthType.unlink.action(this);

  factory OAuth.google() {
    return AdvancedOAuth(
      providerId: GoogleAuthProvider.PROVIDER_ID,
      getCredential: () async {
        var signIn = await GoogleSignIn(scopes: ['email']).signIn();
        if (signIn == null) return null;

        var acc = await (signIn).authentication;

        return GoogleAuthProvider.credential(
          accessToken: acc.accessToken!,
          idToken: acc.idToken!,
        );
      },
    );
  }

  factory OAuth.apple() => ProvidedOAuth(AppleAuthProvider());

  factory OAuth.microsoft() => ProvidedOAuth(MicrosoftAuthProvider());

  factory OAuth.twitter() => ProvidedOAuth(TwitterAuthProvider());

  factory OAuth.github() => ProvidedOAuth(GithubAuthProvider());

  static OAuth? fromId(String providerId) {
    return [
      OAuth.google(),
      OAuth.apple(),
      OAuth.microsoft(),
      OAuth.twitter(),
      OAuth.github(),
    ].firstNullableWhere((oauth) => oauth.providerId == providerId);
  }
}

class ProvidedOAuth extends OAuth {
  final AuthProvider provider;

  ProvidedOAuth(this.provider) : super(provider.providerId);

  @override
  Future<UserCredential> _link() {
    if (kIsWeb) {
      return FirebaseAuth.instance.currentUser!.linkWithPopup(provider);
    } else {
      return FirebaseAuth.instance.currentUser!.linkWithProvider(provider);
    }
  }

  @override
  Future<UserCredential> _reauthenticate() {
    if (kIsWeb) {
      return FirebaseAuth.instance.currentUser!.reauthenticateWithPopup(provider);
    } else {
      return FirebaseAuth.instance.currentUser!.reauthenticateWithProvider(provider);
    }
  }

  @override
  Future<UserCredential> _signIn() {
    if (kIsWeb) {
      return FirebaseAuth.instance.signInWithPopup(provider);
    } else {
      return FirebaseAuth.instance.signInWithProvider(provider);
    }
  }
}

class AdvancedOAuth extends OAuth {
  final FutureOr<AuthCredential?> Function() getCredential;

  AdvancedOAuth({
    required String providerId,
    required this.getCredential,
  }) : super(providerId);

  FutureOr<AuthCredential> get credential async {
    var result = await getCredential.call();
    if (result == null) throw FirebaseAuthException(code: "user-aborted");

    return result;
  }

  @override
  Future<UserCredential> _link() async =>
      FirebaseAuth.instance.currentUser!.linkWithCredential(await credential);

  @override
  Future<UserCredential> _reauthenticate() async =>
      FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(await credential);

  @override
  Future<UserCredential> _signIn() async =>
      FirebaseAuth.instance.signInWithCredential(await credential);
}
