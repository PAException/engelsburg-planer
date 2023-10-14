/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/view/pages/introduction.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/routing/page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Landing page to let the user change several settings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfigState>();

    final tiles = [
      ListTile(
        leading: const Icon(Icons.settings),
        title: Text(context.l10n.configure),
        onTap: () => showConfigure(context),
      ),
      if (config.userType != UserType.other) Pages.subjectSettings.toDrawerListTile(context),
      Pages.substituteSettings.toDrawerListTile(context),
      Pages.notificationSettings.toDrawerListTile(context),
      Pages.themeSettings.toDrawerListTile(context),
    ];

    return ListView.separated(
      itemCount: tiles.length,
      itemBuilder: (context, index) => tiles[index],
      separatorBuilder: (context, index) => const Divider(
        thickness: 2,
        height: 4,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void showConfigure(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SelectUserTypeDialog(),
    );
  }
}
