/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/theme_state.dart';
import 'package:engelsburg_planer/src/view/widgets/color_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

/// Settings page to allow user to change the theme of the app.
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeState>(
      builder: (context, theme, child) => ListView(
        children: [
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.colorScheme),
            children: [
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.systemSetting),
                value: ThemeMode.system,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.defaultMode(),
              ),
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.dark),
                value: ThemeMode.dark,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.darkMode(),
              ),
              RadioListTile<ThemeMode>(
                title: Text(AppLocalizations.of(context)!.light),
                value: ThemeMode.light,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.lightMode(),
              ),
            ],
          ),
          ColorChanger(
            color: theme.primaryColor,
            title: AppLocalizations.of(context)!.primaryColor,
            subtitle: AppLocalizations.of(context)!.tapHereToChangePrimaryColor,
            dialogTitle: AppLocalizations.of(context)!.selectPrimaryColor,
            update: (color) => theme.primaryColor = color,
          ),
          ColorChanger(
            color: theme.secondaryColor,
            title: AppLocalizations.of(context)!.secondaryColor,
            subtitle: AppLocalizations.of(context)!.tapHereToChangeSecondaryColor,
            dialogTitle: AppLocalizations.of(context)!.selectSecondaryColor,
            update: (color) => theme.secondaryColor = color,
          ),
        ],
      ),
    );
  }
}

/// List tile with action to select colors.
class ColorChanger extends StatelessWidget {
  final Color? color;
  final String title;
  final String subtitle;
  final String dialogTitle;
  final void Function(Color? color) update;

  const ColorChanger({
    Key? key,
    this.color,
    required this.title,
    required this.subtitle,
    required this.dialogTitle,
    required this.update,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, maxRadius: 16.0),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(dialogTitle),
            content: SizedBox(
              width: 300,
              child: ColorGrid(
                currentColor: color,
                onColorSelected: (color) {
                  update.call(color);
                  context.pop();
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  update.call(null);
                  context.pop();
                },
                child: Text(AppLocalizations.of(context)!.reset),
              ),
            ],
          ),
        );
      },
    );
  }
}
