/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/theme_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/color_grid.dart';
import 'package:flutter/material.dart';
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
            title: Text(context.l10n.colorScheme),
            children: [
              RadioListTile<ThemeMode>(
                title: Text(context.l10n.systemSetting),
                value: ThemeMode.system,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.defaultMode(),
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.l10n.dark),
                value: ThemeMode.dark,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.darkMode(),
              ),
              RadioListTile<ThemeMode>(
                title: Text(context.l10n.light),
                value: ThemeMode.light,
                groupValue: theme.mode,
                onChanged: (themeMode) => theme.lightMode(),
              ),
            ],
          ),
          ColorChanger(
            color: theme.primaryColor,
            title: context.l10n.primaryColor,
            subtitle: context.l10n.tapHereToChangePrimaryColor,
            dialogTitle: context.l10n.selectPrimaryColor,
            update: (color) => theme.primaryColor = color,
          ),
          ColorChanger(
            color: theme.secondaryColor,
            title: context.l10n.secondaryColor,
            subtitle: context.l10n.tapHereToChangeSecondaryColor,
            dialogTitle: context.l10n.selectSecondaryColor,
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
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  update.call(null);
                  context.pop();
                },
                child: Text(context.l10n.reset),
              ),
            ],
          ),
        );
      },
    );
  }
}
