/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StreamConsumer<NotificationSettings>(
        doc: NotificationSettings.ref().defaultStorage(context),
        errorBuilder: (context, doc, error) => Text(error.toString()),
        itemBuilder: (context, doc, settings) {
          print(settings);

          return ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            SwitchListTile(
              value: settings.enabled,
              title: Text(context.l10n.allowNotifications),
              onChanged: (value) {
                settings.setEnabled(value);
                doc.setDelayed(settings);
              },
            ),
            Disabled(
              disabled: !settings.enabled,
              child: Column(
                children: [
                  const Divider(height: 10),
                  SwitchListTile(
                    secondary: const Icon(Icons.library_books),
                    value: settings.article,
                    title: Text(context.l10n.articles),
                    onChanged: (value) {
                      settings.article = value;
                      doc.setDelayed(settings);
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dashboard),
                    value: settings.substitute,
                    title: Text(context.l10n.substitutes),
                    onChanged: (value) {
                      settings.setSubstitute(value);
                      doc.setDelayed(settings);
                    },
                  ),
                ],
              ),
            ),
          ],
        );
        },
      ),
    );
  }
}
