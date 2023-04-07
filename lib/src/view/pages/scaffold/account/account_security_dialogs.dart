/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/obscured_text_form.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog to request a password reset. If successful this dialog will open
/// the [ResetPasswordDialog].
class RequestPasswordResetDialog extends StatelessWidget {
  /// Initial email to fill in the email text field. Usually used when the user already has an
  /// email to his account linked.
  final String? initialEmail;

  /// True if the password will be set for the first time. E.g. the user has created his account
  /// by OAuth and wants to link his email too.
  final bool set;

  const RequestPasswordResetDialog({
    Key? key,
    this.initialEmail,
    required this.set,
  }) : super(key: key);

  const RequestPasswordResetDialog.set({Key? key, this.initialEmail})
      : set = true,
        super(key: key);

  const RequestPasswordResetDialog.reset({Key? key, this.initialEmail})
      : set = false,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController emailController = TextEditingController(text: initialEmail);

    return AlertDialog(
      title: Text(context.l10n.enterEmail),
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextFormField(
          controller: emailController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: context.l10n.email,
            prefixIcon: const Icon(Icons.mail),
          ),
          validator: (value) {
            if (value == null || value.isBlank) return context.l10n.invalidEmailError;

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: context.pop,
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          child: Text(context.l10n.enterCode),
          onPressed: () {
            context
              ..pop()
              ..dialog(ResetPasswordDialog(set: set));
          },
        ),
        TextButton(
          child: Text(context.l10n.sendEmail),
          onPressed: () async {
            //Set or reset password request

            //TODO
            /*
            RequestBuilder rb = set
                ? requestPasswordSet(emailController.text)
                : requestPasswordReset(emailController.text);

            //Execute request
            var res = await rb.build().api(ignore);
            if (res.errorPresent) {
              context
                ..showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage)
                ..pop();
            } else {
              context
                ..pop()
                ..dialog(ResetPasswordDialog(set: set));
            }
            */
          },
        ),
      ],
    );
  }
}

/// Dialog to enter the code and reset the password.
class ResetPasswordDialog extends StatelessWidget {
  /// True if the password will be set for the first time. E.g. the user has created his account
  /// by OAuth and wants to link his email too.
  ///
  /// This will be only important for the title of the dialog.
  final bool set;

  const ResetPasswordDialog({Key? key, required this.set}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController codeController = TextEditingController();
    TextEditingController passwordController = TextEditingController();

    String title = set ? context.l10n.setPassword : context.l10n.resetPassword;

    return AlertDialog(
      title: Text("$title:"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: codeController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.code,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
            ),
          ),
          PasswordTextFormField(controller: passwordController).paddingAll(8),
        ],
      ),
      actions: [
        TextButton(
          onPressed: context.pop,
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          child: Text(title),
          onPressed: () async {
            if (codeController.text.isEmpty) return;

            //TODO RESET PASSWORD
          },
        ),
      ],
    );
  }
}

/// Dialog to verify the email of an account.
class VerifyEmailDialog extends StatelessWidget {
  const VerifyEmailDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController codeController = TextEditingController();

    return AlertDialog(
      title: Text("${context.l10n.verifyEmail}:"),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              controller: codeController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.code,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: context.pop,
          child: Text(context.l10n.cancel),
        ),
        Consumer<UserState>(
          builder: (context, user, child) => TextButton(
            child: Text(context.l10n.verifyEmail),
            onPressed: () async {
              if (codeController.text.isEmpty) return;

              /*
              final res = await verifyEmail(codeController.text.trim())
                  .build()
                  .api(AuthResponseDTO.fromJson);

              if (res.dataPresent) {
                codeController.clear();
                context.showL10nSnackBar((l10n) => l10n.emailSuccessfulVerified);
                context.pop();
              } else {
                context.showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
              }
               */
            },
          ),
        ),
      ],
    );
  }
}
