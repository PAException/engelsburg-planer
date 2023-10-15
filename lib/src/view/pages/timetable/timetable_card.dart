/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/db/timetable.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'timetable_extended.dart';

/// Timetable card to display the current date
class TimetableDate extends StatelessWidget {
  const TimetableDate({Key? key, required this.date, this.editing = false}) : super(key: key);

  final DateTime date;
  final bool editing;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Center(
        child: Text(
          editing ? date.formatEEEE(context) : date.formatEEEEddMMToNow(context),
          textScaleFactor: 2,
          textAlign: TextAlign.center,
        ),
      ),
    );
}

/// Timetable card to display a break
class TimetableBreak extends StatelessWidget {
  const TimetableBreak({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.passthrough,
        clipBehavior: Clip.hardEdge,
        children: [
          const Center(child: Divider(thickness: 2)),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Theme.of(context).colorScheme.background,
              child: Text(
                context.l10n.break_,
                textScaleFactor: 1.2,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      );
}

/// Timetable card to display one or more free hours
class TimetableFreeHour extends StatelessWidget {
  const TimetableFreeHour({
    Key? key,
    required this.freeHours,
    this.timeSpan,
  }) : super(key: key);

  final int freeHours;
  final String? timeSpan;

  @override
  Widget build(BuildContext context) {
    String count = freeHours > 1 ? "$freeHours " : "";
    String name = freeHours > 1 ? context.l10n.freeHours : context.l10n.freeHour;

    return Tooltip(
      message: timeSpan,
      triggerMode: TooltipTriggerMode.tap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            "$count $name",
            textScaleFactor: 1.8,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

/// Timetable card to display that there are no entries
class TimetableNoEntries extends StatelessWidget {
  const TimetableNoEntries({Key? key, required this.editCallback}) : super(key: key);

  final void Function() editCallback;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: editCallback,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              context.l10n.noTimetable,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
}

/// Timetable card to display a lesson
class TimetableCard extends StatelessWidget {
  const TimetableCard({
    Key? key,
    required this.date,
    required this.entry,
    this.entryDoc,
    this.editing = false,
  }) : super(key: key);

  final DateTime date;
  final TimetableEntry entry;
  final bool editing;

  final Document<TimetableEntry>? entryDoc;

  @override
  Widget build(BuildContext context) {
    final heroTag = StringUtils.randomAlphaNumeric(16);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Hero(
          tag: heroTag,
          //https://github.com/flutter/flutter/issues/34119
          flightShuttleBuilder: (_, __, ___, ____, toHeroContext) =>
              Material(child: toHeroContext.widget),
          child: NullableStreamConsumer<Subject>(
            doc: entry.subject?.defaultStorage(context),
            itemBuilder: (context, doc, subject) => SizedBox(
                width: 500,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: context.subjectColor(subject),
                    child: ListTile(
                      minVerticalPadding: 8,
                      leading: Center(
                        widthFactor: 1,
                        child: Text(entry.lesson.toString(), textScaleFactor: 1.8),
                      ),
                      title: subject != null
                          ? Text(
                            subject.parsedName(context),
                            textScaleFactor: 1.25
                          ) : null,
                      subtitle: TimetableSubtitle(
                        entry: entry,
                        showTeacher: context.read<AppConfigState>().userType == UserType.student,
                        showClassName:
                            context.read<AppConfigState>().userType == UserType.teacher,
                      ),
                      onTap: () => context.pushPage(
                        ExtendedTimetableCard(
                          entry: entry,
                          entryDoc: entryDoc,
                          heroTag: heroTag,
                          date: date,
                          editing: editing,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }
}

class TimetableSubtitle extends StatelessWidget {
  const TimetableSubtitle({
    Key? key,
    required this.entry,
    this.showTeacher = true,
    this.showClassName = false,
  }) : super(key: key);

  final TimetableEntry entry;
  final bool showTeacher;
  final bool showClassName;

  @override
  Widget build(BuildContext context) {
    List<String> properties = [
      if (entry.room != null && entry.room!.isNotEmpty) entry.room!,
      if (showTeacher && entry.teacher != null && entry.teacher!.isNotEmpty) entry.teacher!,
      if (showClassName && entry.className != null && entry.className!.isNotEmpty) entry.className!,
    ];

    return Wrap(
      children: [
        Text(
          properties.join(" - "),
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}
