/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<NotificationSettings>(
      doc: NotificationSettings.get(),
      builder: (context, doc, settings) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: StatefulBuilder(builder: (context, setState) {
            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                SwitchListTile(
                  value: settings.enabled,
                  title: Text(context.l10n.allowNotifications),
                  onChanged: (value) {
                    settings.enabled = value;
                    setState.call(() {});
                    doc.flushDelayed();
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
                          setState.call(() {});
                          doc.flushDelayed();
                        },
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.dashboard),
                        value: settings.substitute,
                        title: Text(context.l10n.substitutes),
                        onChanged: (value) {
                          settings.substitute = value;
                          setState.call(() {});
                          doc.flushDelayed();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
