/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/scaffold/account/account_security_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Consumer<UserState>(
        builder: (context, user, child) => ListView(
          children: [
            GestureDetector(
              onDoubleTap: () => context.go("/account/advanced"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_circle, size: 80)
                            .paddingLTRB(16, 16, 24, 16)
                            .alignAtCenterLeft(),
                        Container(
                          alignment: Alignment.centerLeft,
                          width: MediaQuery.of(context).size.width - 160,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  user.username ?? " ",
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                              const SizedBox(height: 12),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(
                                        user.isVerified ? Icons.done : Icons.close_rounded,
                                        size: 20,
                                      ),
                                    ),
                                    Text(
                                      user.isVerified
                                          ? AppLocalizations.of(context)!.emailVerified
                                          : AppLocalizations.of(context)!.emailNotVerified,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!user.isVerified)
                      ListTile(
                        onTap: () => context.dialog(const VerifyEmailDialog()),
                        leading: const Icon(Icons.email),
                        title: Text(AppLocalizations.of(context)!.verifyEmail),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 10, thickness: 3),
            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: Text(AppLocalizations.of(context)!.security),
              onTap: () => context.go("/account/security"),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context)!.logout),
              onTap: () {
                user.instance.signOut();
                //TODO: remove device from notifications
                context.go("/");
              },
            ),
          ],
        ),
      ),
    );
  }
}
