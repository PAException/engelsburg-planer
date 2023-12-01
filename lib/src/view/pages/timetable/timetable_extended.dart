/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/timetable.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_select_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:provider/provider.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:engelsburg_planer/src/view/widgets/teacher_list_tile.dart';

class ExtendedTimetableCard extends CompactStatefulWidget {
  const ExtendedTimetableCard({
    super.key,
    required this.entry,
    required this.heroTag,
    required this.date,
    this.entryDoc,
    this.editing = false,
  });

  final TimetableEntry entry;
  final String heroTag;
  final DateTime date;
  final bool editing;

  final Document<TimetableEntry>? entryDoc;

  @override
  State<ExtendedTimetableCard> createState() => _ExtendedTimetableCardState();
}

class _ExtendedTimetableCardState extends State<ExtendedTimetableCard> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  late bool _editing;
  late TimetableEntry entry;
  Document<TimetableEntry>? entryDoc;
  Document<Subject>? currentSubject;

  @override
  void initState() {
    super.initState();
    _editing = widget.editing;
    entryDoc = widget.entryDoc;
  }

  String _timeOfLessons() {
    String start = Substitute.lessonStart(widget.entry.lesson);
    String end = Substitute.lessonEnd(widget.entry.lesson);
    String suffix = context.l10n.oclock;

    return "$start - $end $suffix";
  }

  Future<void> savePossibleChanges() async {
    if (!_editing) return;
    var data = entryDoc?.data ?? entry;

    bool markFlush = false;
    if (currentSubject != null && currentSubject != data.subject) {
      data.subject = currentSubject;
      markFlush = true;
    }
    if (_classNameController.text != data.className) {
      data.className = _classNameController.text;
      markFlush = true;
    }
    if (_teacherController.text != data.teacher) {
      data.teacher = _teacherController.text;
      markFlush = true;
    }
    if (_roomController.text != data.room) {
      data.room = _roomController.text;
      markFlush = true;
    }

    if (entryDoc == null) {
      entryDoc = await Timetable.entries().defaultStorage(context).addDocument(data);
      if ((await SubstituteSettings.ref().defaultStorage(globalContext()).load()).byTimetable) {
        NotificationSettings.ref().offline.load().then((value) => value.updateSubstituteSettings());
      }
    } else if (markFlush) {
      entryDoc!.setDelayed(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TimetableEntry>(
      initialData: widget.entry,
      stream: entryDoc?.defaultStorage(context).stream().map((e) => e ?? widget.entry),
      builder: (context, snapshot) {
        entry = snapshot.data!;

        _classNameController.text = entry.className ?? "";
        _teacherController.text = entry.teacher ?? "";
        _roomController.text = entry.room ?? "";

        return PopScope(
          canPop: true,
          onPopInvoked: (_) => savePossibleChanges(),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              titleSpacing: 0,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: context.pop,
                ),
              ),
              actions: [
                const Flex(direction: Axis.horizontal),
                if (_editing && entryDoc != null)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      entryDoc?.delete();
                      context.pop();
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(_editing ? Icons.done : Icons.edit_outlined),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      setState(() {
                        //If editing turned off save changes
                        savePossibleChanges();

                        _editing = !_editing;
                      });
                    },
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<Subject?>(
                initialData: entry.subject?.defaultStorage(context).data,
                stream: entry.subject?.defaultStorage(context).stream(),
                builder: (context, snapshot) {
                  var subject = currentSubject?.data ?? snapshot.data;

                  return Consumer<AppConfigState>(
                    builder: (context, config, _) {
                      return ListView(
                        children: [
                          ListTile(
                            leading: Hero(
                              tag: widget.heroTag,
                              child: SizedBox.square(
                                dimension: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: context.subjectColor(subject),
                                  ),
                                ),
                              ),
                            ),
                            title: Align(
                              alignment: Alignment.centerLeft,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  subject?.parsedName(context) ?? context.l10n.pickSubject,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                            subtitle: Text(widget.date.formatEEEEddMMToNow(context)),
                            onTap: () async {
                              Document<Subject>? res = await context.pushPage(
                                  const SelectSubjectPage()
                              );
                              if (res == null) return;

                              currentSubject = res;
                              if (!_editing) savePossibleChanges();
                              setState(() {});
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.access_time),
                            dense: true,
                            title: Text(
                              entry.lesson.toString(),
                              style: const TextStyle(fontSize: 18),
                            ),
                            subtitle: Text(_timeOfLessons()),
                          ),
                          if ((!_classNameController.text.isBlank || _editing) &&
                              config.userType == UserType.teacher)
                            ListTile(
                              leading: const Icon(Icons.class_),
                              title: _editing
                                  ? TextField(
                                    controller: _classNameController,
                                    style: const TextStyle(fontSize: 20),
                                  )
                                  : Text(
                                    _classNameController.text,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                            ),
                          if (config.userType == UserType.student)
                            TeacherListTile.edit(
                              editing: _editing,
                              controller: _teacherController,
                            ),
                          if (!_roomController.text.isBlank || _editing)
                            ListTile(
                              leading: const Icon(Icons.room),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: _editing
                                  ? TextField(
                                    controller: _roomController,
                                    style: const TextStyle(fontSize: 20),
                                  )
                                  : Text(
                                    _roomController.text,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
