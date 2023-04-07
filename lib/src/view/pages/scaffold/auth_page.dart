/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/account/account_security_dialogs.dart';
import 'package:engelsburg_planer/src/view/widgets/animated_app_name.dart';
import 'package:engelsburg_planer/src/view/widgets/oauth_button.dart';
import 'package:engelsburg_planer/src/view/widgets/obscured_text_form.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_debouncer/tap_debouncer.dart';

typedef Action = FutureOr<bool> Function(BuildContext context, String email, String password);

FutureOr<bool> signInAction(BuildContext context, String email, String password) async {
  try {
    var value = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (value.user?.metadata.creationTime == value.user?.metadata.lastSignInTime) {
      value.user?.sendEmailVerification();
    }
    return true;
  } on FirebaseAuthException catch (e) {
    switch (e.code) {
      case "user-not-found":
        context.showL10nSnackBar((l10n) => l10n.userNotFound);
        break;
      case "wrong-password":
        context.showL10nSnackBar((l10n) => l10n.wrongPassword);
        break;
      case "invalid-email":
        context.showL10nSnackBar((l10n) => l10n.invalidEmailError);
        break;
      case "email-already-in-use":
        context.showL10nSnackBar((l10n) => l10n.accountAlreadyExistingError);
        break;
      default:
        context.showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
    }
    return false;
  }
}

void defaultOnSuccessCallback() {
  globalContext().showL10nSnackBar((l10n) => l10n.loggedIn);
  globalContext().go("/");
}

class SignInPage extends CompactStatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ListView(
          children: [
            const AnimatedAppName().toCenter().paddingAll(16),
            25.0.heightBox,
            AuthenticationForm(),
          ],
        ),
      ),
    );
  }
}

class EmailPasswordBottomSheet extends StatelessWidget {
  final Action action;
  final VoidCallback onSuccess;
  final String? email;
  final bool dismissible;

  const EmailPasswordBottomSheet({
    super.key,
    this.dismissible = false,
    this.email,
    this.action = signInAction,
    this.onSuccess = defaultOnSuccessCallback,
  });

  Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: dismissible,
      builder: (_) => this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets + const EdgeInsets.all(20),
      child: AuthenticationForm(
        showOAuth: false,
        validatePassword: false,
        autoFocusEmail: true,
        action: action,
        onSuccess: onSuccess,
      ),
    );
  }
}

/// Sub widget to handle the form area of the authentication page.
class AuthenticationForm extends StatelessWidget {
  final Action action;
  final VoidCallback onSuccess;
  final String? email;
  final bool showOAuth;
  final bool showResetPassword;
  final bool validatePassword;
  final bool autoFocusEmail;

  final _emailAndPasswordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailTextController;
  final _passwordTextController = TextEditingController();

  AuthenticationForm({
    Key? key,
    this.showOAuth = true,
    this.showResetPassword = true,
    this.validatePassword = true,
    this.autoFocusEmail = false,
    this.email,
    this.action = signInAction,
    this.onSuccess = defaultOnSuccessCallback,
  }) : super(key: key) {
    _emailTextController = TextEditingController(text: email);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _emailAndPasswordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            autofocus: autoFocusEmail,
            controller: _emailTextController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: context.l10n.email,
              prefixIcon: const Icon(Icons.mail),
            ),
            validator: (value) {
              if (value == null || value.isBlank) {
                return context.l10n.invalidEmailError;
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: PasswordTextFormField(
              controller: _passwordTextController,
              validator: (value) => validatePassword ? passwordValidator(context, value) : null,
            ),
          ),
          Container(
            height: 64.0,
            padding: const EdgeInsets.only(top: 16.0),
            child: TapDebouncer(
              onTap: () async {
                //Validate
                if (!_emailAndPasswordFormKey.currentState!.validate()) return;

                //Await action of auth type
                var success = await action.call(
                    context, _emailTextController.text, _passwordTextController.text);
                if (success) {
                  onSuccess.call();
                  _emailTextController.clear();
                  _passwordTextController.clear();
                }
              },
              builder: (context, onTap) => ElevatedButton(
                onPressed: onTap,
                child: onTap == null
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SpinKitThreeBounce(
                            color: Theme.of(context).buttonTheme.colorScheme!.surface,
                          ),
                        ),
                      )
                    : Text(
                        context.l10n.signIn,
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
          if (showResetPassword)
            Container(
              padding: const EdgeInsets.only(top: 12, right: 8),
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => context.dialog(const RequestPasswordResetDialog.reset()),
                child: Text(context.l10n.resetPassword).fontSize(16),
              ),
            ),
          if (showOAuth)
            const Divider(height: 10, thickness: 3).paddingSymmetric(vertical: 12, horizontal: 0),
          if (showOAuth)
            ...OAuthButton.getAll(context).map(
              (oauthButton) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 60,
                  width: 300,
                  child: oauthButton,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String? passwordValidator(BuildContext context, String value) {
    if (value.length < 8) {
      return context.l10n.passwordMin8Chars;
    } else if (!value.contains(RegExp(r"([A-ZÄÖÜa-zäöü])+(\d)+"))) {
      return context.l10n.passwordMustContainNumber;
    }

    return null;
  }
}
