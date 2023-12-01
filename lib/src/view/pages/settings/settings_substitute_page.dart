/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';

class SubstituteSettingsPage extends StatelessWidget {
  const SubstituteSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    TextEditingController classController = TextEditingController(),
        teacherController = TextEditingController();

    var notificationSettings = NotificationSettings.ref().offline;
    return StreamConsumer<SubstituteSettings>(
      doc: SubstituteSettings.ref().defaultStorage(context),
      itemBuilder: (context, doc, settings) {

        return Scaffold(
          body: StatefulBuilder(builder: (context, setState) {
            return ListView(
              children: [
                ListTile(
                  title: Text(
                    "${context.l10n.filterBy}:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textScaler: const TextScaler.linear(1.2),
                  ),
                ),
                SwitchExpandable(
                  switchListTile: SwitchListTile(
                    value: settings.byClasses,
                    onChanged: (value) {
                      settings.byClasses = value;
                      doc.setDelayed(
                        settings,
                        onSuccess: () => notificationSettings.load().then(
                                (value) => value.updateSubstituteSettings()),
                      );
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
                                    settings.classes.remove(e);
                                    doc.setDelayed(
                                      settings,
                                      onSuccess: () => notificationSettings.load().then(
                                              (value) => value.updateSubstituteSettings()),
                                    );
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
                            doc.setDelayed(
                              settings,
                              onSuccess: () => notificationSettings.load().then(
                                      (value) => value.updateSubstituteSettings()),
                            );
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
                      settings.byTeacher = value;
                      doc.setDelayed(
                        settings,
                        onSuccess: () => notificationSettings.load().then(
                                (value) => value.updateSubstituteSettings()),
                      );
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
                                    settings.teacher.remove(e);
                                    doc.setDelayed(
                                      settings,
                                      onSuccess: () => notificationSettings.load().then(
                                              (value) => value.updateSubstituteSettings()),
                                    );
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
                            doc.setDelayed(
                              settings,
                              onSuccess: () => notificationSettings.load().then(
                                      (value) => value.updateSubstituteSettings()),
                            );
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
                    settings.byTimetable = value;
                    doc.setDelayed(
                      settings,
                      onSuccess: () => notificationSettings.load().then(
                              (value) => value.updateSubstituteSettings()),
                    );
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
