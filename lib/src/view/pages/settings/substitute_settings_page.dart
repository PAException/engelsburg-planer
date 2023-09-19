/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/models/db/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';

class SubstituteSettingsPage extends StatelessWidget {
  const SubstituteSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextEditingController classController = TextEditingController(),
        teacherController = TextEditingController();

    return StreamConsumer<SubstituteSettings>(
      doc: SubstituteSettings.get(),
      builder: (context, doc, settings) {
        return Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            return ListView(
              children: [
                ListTile(
                  title: Text(
                    "${context.l10n.filterBy}:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textScaleFactor: 1.2,
                  ),
                ),
                SwitchExpandable(
                  switchListTile: SwitchListTile(
                    value: settings.byClasses,
                    onChanged: (value) {
                      setState.call(() => settings.byClasses = value);
                      NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                      doc.flushDelayed();
                    },
                    title: Text(context.l10n.class_),
                  ),
                  curve: Curves.decelerate,
                  child: Column(
                    children: [
                      if (settings.classes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Wrap(
                              runAlignment: WrapAlignment.start,
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: settings.classes.map((e) {
                                Color color = Theme.of(context).colorScheme.secondary;
                                return Chip(
                                  label: Text(e.toUpperCase(), style: TextStyle(color: color)),
                                  deleteIconColor: color,
                                  shape: StadiumBorder(side: BorderSide(color: color)),
                                  onDeleted: () {
                                    setState.call(() => settings.classes.remove(e));
                                    NotificationSettings.get()
                                        .load()
                                        .then((value) => value.updateSubstitutes());
                                    doc.flushDelayed();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: TextFormField(
                          controller: classController,
                          onFieldSubmitted: (text) {
                            settings.classes.add(text);
                            classController.clear();
                            setState.call(() {});
                            NotificationSettings.get()
                                .load()
                                .then((value) => value.updateSubstitutes());
                            doc.flushDelayed();
                          },
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            label: Text(context.l10n.add),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: GestureDetector(
                                onTap: () => classController.clear(),
                                child: const Icon(Icons.clear_outlined, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                SwitchExpandable(
                  switchListTile: SwitchListTile(
                    value: settings.byTeacher,
                    onChanged: (value) {
                      setState.call(() => settings.byTeacher = value);
                      NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                      doc.flushDelayed();
                    },
                    title: Text(context.l10n.teacher),
                  ),
                  curve: Curves.decelerate,
                  child: Column(
                    children: [
                      if (settings.teacher.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Wrap(
                              runAlignment: WrapAlignment.start,
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: settings.teacher.map((e) {
                                Color color = Theme.of(context).colorScheme.secondary;
                                return Chip(
                                  label: Text(e.toUpperCase(), style: TextStyle(color: color)),
                                  deleteIconColor: color,
                                  shape: StadiumBorder(side: BorderSide(color: color)),
                                  onDeleted: () {
                                    setState.call(() => settings.teacher.remove(e));
                                    NotificationSettings.get()
                                        .load()
                                        .then((value) => value.updateSubstitutes());
                                    doc.flushDelayed();
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: TextFormField(
                          controller: teacherController,
                          onFieldSubmitted: (text) {
                            settings.teacher.add(text);
                            teacherController.clear();
                            setState.call(() {});
                            NotificationSettings.get()
                                .load()
                                .then((value) => value.updateSubstitutes());
                            doc.flushDelayed();
                          },
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            label: Text(context.l10n.add),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 0, 4, 0),
                              child: GestureDetector(
                                onTap: () => teacherController.clear(),
                                child: const Icon(Icons.clear_outlined, size: 24),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  value: settings.byTimetable,
                  onChanged: (value) {
                    setState.call(() => settings.byTimetable = value);
                    NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                    doc.flushDelayed();
                  },
                  title: Text(context.l10n.timetable),
                ),
              ],
            );
          }),
        );
      },
    );
  }
}
