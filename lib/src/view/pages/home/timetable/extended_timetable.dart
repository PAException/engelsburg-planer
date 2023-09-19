/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/api/substitutes.dart';
import 'package:engelsburg_planer/src/models/db/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/db/timetable.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/select_subject_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExtendedTimetableCard extends CompactStatefulWidget {
  const ExtendedTimetableCard({
    Key? key,
    required this.entry,
    required this.heroTag,
    required this.date,
    this.entryDoc,
    this.editing = false,
  }) : super(key: key);

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
      entryDoc = await Timetable.get().entries.add(data);
      NotificationSettings.get().load().then((value) => value.updateSubstitutes());
    } else if (markFlush) {
      entryDoc!.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<TimetableEntry>(
      initialData: widget.entry,
      stream: entryDoc?.snapshots().map((e) => e ?? widget.entry),
      builder: (context, snapshot) {
        entry = snapshot.data!;

        _classNameController.text = entry.className ?? "";
        _teacherController.text = entry.teacher ?? "";
        _roomController.text = entry.room ?? "";

        return WillPopScope(
          onWillPop: () async {
            savePossibleChanges();
            return true;
          },
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
                if (_editing)
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
                initialData: entry.subject?.data,
                stream: entry.subject?.snapshots(),
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
                            onTap: _editing
                                ? () async {
                                    Document<Subject>? res =
                                        await context.pushPage(const SelectSubjectPage());
                                    if (res == null) return;

                                    currentSubject = res;
                                    setState(() {});
                                  }
                                : null,
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
                              config.appType == AppType.teacher)
                            ListTile(
                              leading: const Icon(Icons.class_),
                              dense: true,
                              title: TextField(
                                controller: _classNameController,
                                decoration: InputDecoration(
                                  border: !_editing ? InputBorder.none : null,
                                ),
                                enabled: _editing,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          if ((!_teacherController.text.isBlank || _editing) &&
                              config.appType == AppType.student)
                            ListTile(
                              leading: const Icon(Icons.portrait),
                              dense: true,
                              title: TextField(
                                controller: _teacherController,
                                decoration: InputDecoration(
                                  border: !_editing ? InputBorder.none : null,
                                ),
                                enabled: _editing,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          if (!_roomController.text.isBlank || _editing)
                            ListTile(
                              leading: const Icon(Icons.room),
                              dense: true,
                              title: TextField(
                                controller: _roomController,
                                decoration: InputDecoration(
                                  border: !_editing ? InputBorder.none : null,
                                ),
                                enabled: _editing,
                                style: const TextStyle(fontSize: 18),
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
