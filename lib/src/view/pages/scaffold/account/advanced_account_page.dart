/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:convert';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/api/request.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/api_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page to display advanced account actions like requesting all
/// saved data as well as deleting the account of the user permanently.
class AccountAdvancedPage extends StatelessWidget {
  const AccountAdvancedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.advanced),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.advancedAccountOptions,
                  style: Theme.of(context).textTheme.headline5,
                ),
                15.heightBox,
                Text(
                  context.l10n.advancedAccountOptionsDescription,
                  style: context.theme.textTheme.caption,
                ),
              ],
            ),
          ),
          ListTile(
            onTap: () => context.push(const AccountData()),
            leading: const Icon(Icons.analytics_outlined),
            title: Text(context.l10n.requestAccountData),
          ),
          ListTile(
            onTap: () => context.dialog(const AccountDeleteConfirmationDialog()),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(context.l10n.deleteAccount),
            subtitle: Row(
              children: [
                const Icon(Icons.warning).paddingOnly(right: 8),
                Text(context.l10n.cannotBeUndone),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmation dialog to confirm the deletion of a user's account
class AccountDeleteConfirmationDialog extends StatelessWidget {
  const AccountDeleteConfirmationDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.deleteAccount),
      content: Text(context.l10n.confirmDeleteAccount),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          child: Text(context.l10n.delete),
          onPressed: () async {
            var res = await deleteUser().build().api(ignore);
            if (res.errorPresent) {
              context.showL10nSnackBar((l10n) => l10n.unexpectedErrorMessage);
            } else {
              context.popUntil("/");
            }
          },
        ),
      ],
    );
  }
}

/// Page to display all account data of a user
class AccountData extends StatelessWidget {
  const AccountData({Key? key}) : super(key: key);

  static const encoder = JsonEncoder.withIndent('  ');

  @override
  Widget build(BuildContext context) {
    String? accountData;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.accountData),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => Clipboard.setData(ClipboardData(text: accountData)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: ApiFutureBuilder(
            request: getUserData().build(),
            parser: json,
            dataBuilder: (json, refresh, context) {
              accountData = encoder.convert(json);

              return RefreshIndicator(
                onRefresh: refresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SelectableText(accountData!),
                ),
              );
            },
            errorBuilder: (error, context) => Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  context.l10n.unexpectedErrorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
