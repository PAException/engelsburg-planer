/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/account/account_security_dialogs.dart';
import 'package:engelsburg_planer/src/view/widgets/oauth_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//TODO create sub widgets => test the layout (column > column)
/// Page to access account security settings of a user. E.g. reset password, add OAuth.
class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(context.l10n.security),
      ),
      body: Consumer<UserState>(
        builder: (context, user, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.connectedAccounts,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  15.heightBox,
                  Text(context.l10n.connectedAccountsDescription,
                      style: Theme.of(context).textTheme.caption),
                ],
              ),
            ),
            ListView(
              shrinkWrap: true,
              children: [
                //if (!user.loginVia!.contains("email")) const SetPasswordTile(),

                //All OAuth tiles
                OAuthTile.google(),
              ],
            ),
            const Divider(height: 10, thickness: 3).paddingSymmetric(horizontal: 8),
            if (user.email != null)
              Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.resetPassword,
                      style: Theme.of(context).textTheme.headline5,
                    ),
                    const SizedBox(height: 15),
                    Text(context.l10n.resetPasswordDescription,
                        style: Theme.of(context).textTheme.caption),
                  ],
                ),
              ),
            if (user.email != null)
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(
                        context.l10n.resetPassword,
                        style: Theme.of(context).textTheme.bodyText2!.copyWith(
                              fontSize: 18,
                              color: Theme.of(context).textTheme.headline6!.color,
                            ),
                      ),
                      leading: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.vpn_key, size: 32),
                      ),
                      onTap: () {
                        context.dialog(RequestPasswordResetDialog.reset(initialEmail: user.email));
                      },
                    ),
                  ],
                ),
              ),
            if (user.email != null)
              const Divider(height: 10, thickness: 3).paddingSymmetric(horizontal: 8),
          ],
        ),
      ),
    );
  }
}

/// ListTile to handle the first set of an email.
class SetPasswordTile extends StatelessWidget {
  const SetPasswordTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.dialog(const RequestPasswordResetDialog.set()),
      leading: const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.email, size: 32),
      ),
      title: Text(
        context.l10n.email,
        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
