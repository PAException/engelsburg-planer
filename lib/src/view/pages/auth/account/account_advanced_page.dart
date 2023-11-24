/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/grades.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/tasks.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/timetable.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/auth/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page to display advanced account actions like requesting all
/// saved data as well as deleting the account of the user permanently.
class AccountAdvancedPage extends StatelessWidget {
  const AccountAdvancedPage({super.key});

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
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                15.heightBox,
                Text(
                  context.l10n.advancedAccountOptionsDescription,
                  style: context.theme.textTheme.bodySmall,
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
  const AccountDeleteConfirmationDialog({super.key});

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
            context.pushPage(const SignInPage()).then((value) {
              try {
                FirebaseAuth.instance.currentUser?.delete();
              } catch (_) {}
            });
          },
        ),
      ],
    );
  }
}

/// Page to display all account data of a user
class AccountData extends StatelessWidget {
  const AccountData({super.key});

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
            onPressed: () {
              if (accountData == null) return;
              Clipboard.setData(ClipboardData(text: accountData!));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: FutureBuilder<List>(
            future: Future.wait([
              Subjects.ref().defaultStorage(context).load(),
              Timetable.ref().defaultStorage(context).load(),
              Grades.ref().defaultStorage(context).load(),
              Tasks.ref().defaultStorage(context).load(),

              Subjects.entries().defaultStorage(context).documents(),
              Timetable.entries().defaultStorage(context).documents(),
              Grades.entries().defaultStorage(context).documents(),
              Tasks.entries().defaultStorage(context).documents(),
            ]),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var data = snapshot.data!.where((element) => element is! List || element.isNotEmpty);
              accountData = encoder.convert(data.toList());

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SelectableText(accountData!),
              );
            },
          ),
        ),
      ),
    );
  }
}
