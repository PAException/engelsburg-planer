import 'package:engelsburg_planer/src/introduction.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/page.dart';
import 'package:engelsburg_planer/src/view/widgets/locked.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

/// Landing page to let the user change several settings.
class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ListTile(
        leading: const Icon(Icons.settings),
        title: Text(context.l10n.configure),
        onTap: () => showConfigure(context),
      ),
      Pages.subjectSettings.toDrawerListTile(context),
      Locked(
        enforceVerified: false,
        child: Pages.substituteSettings.toDrawerListTile(context),
      ),
      Locked(
        child: ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(AppLocalizations.of(context)!.notificationSettings),
          onTap: () => context.go("/settings/notifications"),
        ),
      ),
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
      builder: (context) => const SelectAppTypeDialog(),
    );
  }
}
