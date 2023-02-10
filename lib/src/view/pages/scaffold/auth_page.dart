/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/account/account_security_dialogs.dart';
import 'package:engelsburg_planer/src/view/widgets/animated_app_name.dart';
import 'package:engelsburg_planer/src/view/widgets/oauth_button.dart';
import 'package:engelsburg_planer/src/view/widgets/obscured_text_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:tap_debouncer/tap_debouncer.dart';

void onSuccess() {
  globalContext().showL10nSnackBar((l10n) => l10n.loggedIn);
  globalContext().go("/");
}

/// Page to sign in or up. Because those pages did not differ that much in the design
/// but the components this widget was created. It needs to know how to construct the
/// authentication page on different authentication types. All varying components are defined
/// in [AuthenticationType] and are retrieved while building if necessary.
class AuthenticationPage extends StatelessWidget {
  final AuthenticationType type;

  const AuthenticationPage({Key? key, required this.type}) : super(key: key);

  const AuthenticationPage.signUp({Key? key})
      : type = const SignUpAuthentication(onSuccess),
        super(key: key);

  const AuthenticationPage.signIn({Key? key})
      : type = const SignInAuthentication(onSuccess),
        super(key: key);

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
            AuthenticationForm(type: type),
          ],
        ),
      ),
      bottomSheet: type.dataDisclaimer(context),
    );
  }
}

/// Sub widget to handle the form area of the authentication page.
class AuthenticationForm extends StatelessWidget {
  final AuthenticationType type;
  final bool showOAuth;

  final _emailAndPasswordFormKey = GlobalKey<FormState>();

  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  AuthenticationForm({Key? key, required this.type, this.showOAuth = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _emailAndPasswordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailTextController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: AppLocalizations.of(context)!.email,
              prefixIcon: const Icon(Icons.mail),
            ),
            validator: (value) {
              if (value == null || value.isBlank) {
                return AppLocalizations.of(context)!.invalidEmailError;
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: PasswordTextFormField(
              controller: _passwordTextController,
              validator: type.passwordValidator(context),
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
                await type.action(
                  context,
                  _emailTextController,
                  _passwordTextController,
                );
                _emailTextController.clear();
                _passwordTextController.clear();
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
                        type.name(context),
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ),
          type.resetPassword(context),
          const Divider(height: 10, thickness: 3).paddingSymmetric(vertical: 12, horizontal: 0),
          SizedBox(
            height: 60,
            width: 300,
            child: type is SignUpAuthentication
                ? OAuthButton.googleSignUp(context)
                : OAuthButton.googleSignIn(context),
          ),
        ],
      ),
    );
  }
}

/// Authentication type to handle specific parts of the page.
abstract class AuthenticationType {
  final VoidCallback onSuccess;

  const AuthenticationType(this.onSuccess);

  String name(BuildContext context);

  Widget? dataDisclaimer(BuildContext context);

  FormFieldValidator? passwordValidator(BuildContext context);

  Future<void> action(
    BuildContext context,
    TextEditingController email,
    TextEditingController password,
  );

  Widget resetPassword(BuildContext context);
}

/// Used to handle all sign up components on the authentication page
class SignUpAuthentication extends AuthenticationType {
  const SignUpAuthentication(super.onSuccess);

  @override
  String name(BuildContext context) => AppLocalizations.of(context)!.signUp;

  @override
  Widget? dataDisclaimer(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0),
        Row(
          children: [
            const Icon(Icons.lock).paddingAll(16),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 8.0, 8.0, 8.0),
                child: Text(AppLocalizations.of(context)!.dataDisclaimer),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  FormFieldValidator? passwordValidator(BuildContext context) => (value) {
        if (value.length < 8) {
          return AppLocalizations.of(context)!.passwordMin8Chars;
        } else if (!value.contains(RegExp(r"([A-ZÄÖÜa-zäöü])+([0-9])+"))) {
          return AppLocalizations.of(context)!.passwordMustContainNumber;
        }
        return null;
      };

  @override
  Future<void> action(
    BuildContext context,
    TextEditingController email,
    TextEditingController password,
  ) async {
    try {
      FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      )
          .then((value) {
        onSuccess.call();
      });
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "email-already-in-use":
          context.showL10nSnackBar((l10n) => l10n.accountAlreadyExistingError);
          break;
        case "invalid-email":
          context.showL10nSnackBar((l10n) => l10n.invalidEmailError);
          break;
        default:
          context.showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
      }
    }
  }

  @override
  Widget resetPassword(BuildContext context) => Container();
}

/// Used to handle all the sign in parts of the authentication page
class SignInAuthentication extends AuthenticationType {
  const SignInAuthentication(super.onSuccess);

  @override
  String name(BuildContext context) => AppLocalizations.of(context)!.signIn;

  @override
  Widget? dataDisclaimer(BuildContext context) => null;

  @override
  FormFieldValidator? passwordValidator(BuildContext context) => null;

  @override
  Future<void> action(
    BuildContext context,
    TextEditingController email,
    TextEditingController password,
  ) async {
    try {
      FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      )
          .then((value) {
        onSuccess.call();
      });
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
        default:
          context.showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
      }
    }
  }

  @override
  Widget resetPassword(BuildContext context) {
    return InkWell(
      onTap: () => context.dialog(const RequestPasswordResetDialog.reset()),
      child: Text(AppLocalizations.of(context)!.resetPassword).fontSize(16),
    ).alignAtCenterRight().paddingOnly(top: 12, right: 8);
  }
}
