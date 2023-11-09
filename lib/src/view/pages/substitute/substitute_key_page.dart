/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';


class SubstituteKeyPage extends StatelessWidget {
  const SubstituteKeyPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future? fetchingKeyHash;
    String? substituteKeyHash;

    fetchingKeyHash ??= getSubstituteKeyHash().build().api<String>((json) {
      if (json is String) return json;
      if (json is List) return json[0];

      return json["sha1"];
    }).then((value) {
      if (value.dataPresent) {
        substituteKeyHash = value.data;
      } else {
        fetchingKeyHash = null;
      }
    });

    var keyController = TextEditingController();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.l10n.verifyUserIsStudent,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            TextFormField(
              controller: keyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.substitutesPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            Container(
              height: 64.0,
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (keyController.text.isEmpty) return;
                  var substituteKey = keyController.text;

                  var digest = sha1.convert(utf8.encode(substituteKey));
                  if (substituteKeyHash == null || digest.toString() == substituteKeyHash) {
                    var doc = SubstituteSettings.ref().defaultStorage(context);
                    doc.load().then((value) {
                      value.password = substituteKey;
                      NotificationSettings.ref().defaultStorage(context).load().then((value) => value.updateSubstituteSettings());
                      doc.set(value);
                    });
                  } else {
                    context.showL10nSnackBar((l10n) => l10n.wrongSubstituteKeyError);
                  }
                },
                child: Text(
                  context.l10n.check,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
