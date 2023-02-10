import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/controller/subject_controller.dart';
import 'package:engelsburg_planer/src/controller/timetable_controller.dart';
import 'package:engelsburg_planer/src/models/api/dto/substitute_dto.dart';
import 'package:engelsburg_planer/src/models/api/subject.dart';
import 'package:engelsburg_planer/src/models/api/timetable.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
              color: Theme.of(context).backgroundColor,
              child: Text(
                AppLocalizations.of(context)!.break_,
                textScaleFactor: 1.2,
                style: Theme.of(context).textTheme.caption,
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
    String name = freeHours > 1
        ? AppLocalizations.of(context)!.freeHours
        : AppLocalizations.of(context)!.freeHour;

    return Tooltip(
      message: timeSpan,
      triggerMode: TooltipTriggerMode.tap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            "$count $name",
            textScaleFactor: 1.8,
            style: Theme.of(context).textTheme.caption,
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
              AppLocalizations.of(context)!.noTimetable,
              style: Theme.of(context).textTheme.caption,
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
    required this.refreshCallback,
    this.editing = false,
  }) : super(key: key);

  final DateTime date;
  final TimetableEntry entry;
  final bool editing;

  //To trigger refresh if changes happened
  final void Function() refreshCallback;

  @override
  Widget build(BuildContext context) {
    Subject? subject = _getSubject(context, entry.subjectId);
    final heroTag = StringUtils.randomAlphaNumeric(16);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Hero(
        tag: heroTag,
        //https://github.com/flutter/flutter/issues/34119
        flightShuttleBuilder: (_, __, ___, ____, toHeroContext) =>
            Material(child: toHeroContext.widget),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: _subjectColor(context, subject),
            child: ListTile(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExtendedTimetableCard(
                      timetableEntry: entry,
                      heroTag: heroTag,
                      date: date,
                      editing: editing,
                    ),
                  ),
                );
                refreshCallback();
              },
              minVerticalPadding: 8,
              leading: Center(
                widthFactor: 1,
                child: Text(
                  entry.lesson.toString(),
                  textScaleFactor: 1.8,
                ),
              ),
              title: entry.subjectId != null
                  ? Text(
                      _subjectName(context, subject),
                      textScaleFactor: 1.25,
                    )
                  : null,
              subtitle: _buildText(
                context: context,
                entry: entry,
                showTeacher: true, //TODO change if teacher using
                showClassName: false,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildText({
    required BuildContext context,
    required TimetableEntry entry,
    bool showTeacher = false,
    bool showClassName = false,
  }) {
    var properties = [];

    if (entry.room != null) properties.add(entry.room!);
    if (showTeacher && entry.teacher != null) properties.add(entry.teacher!);
    if (showClassName && entry.className != null) properties.add(entry.className!);

    String text = properties.join(" - ");

    return Wrap(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }
}

Subject? _getSubject(BuildContext context, int? subjectId) {
  return subjectId != null ? context.data<SubjectService>()!.getSubject(subjectId) : null;
}

String _subjectName(BuildContext context, Subject? subject) {
  if (subject == null) return AppLocalizations.of(context)!.pickSubject;

  return context.data<SubjectService>()!.getBaseSubject(subject).localization(context) ??
      AppLocalizations.of(context)!.pickSubject;
}

Color _subjectColor(BuildContext context, Subject? subject) {
  return subject?.parsedColor ?? Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.15);
}

class ExtendedTimetableCard extends StatefulWidget {
  const ExtendedTimetableCard({
    Key? key,
    required this.timetableEntry,
    required this.heroTag,
    required this.date,
    this.editing = false,
  }) : super(key: key);

  final TimetableEntry timetableEntry;
  final String heroTag;
  final DateTime date;
  final bool editing;

  @override
  State<ExtendedTimetableCard> createState() => _ExtendedTimetableCardState();
}

class _ExtendedTimetableCardState extends State<ExtendedTimetableCard>
    with DataStateMixin<TimetableService> {
  Subject? _subject;
  late bool _editing;

  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subject = _getSubject(context, widget.timetableEntry.subjectId);
    _editing = widget.editing;
  }

  String _timeOfLessons() {
    String start = SubstituteDTO.lessonStart(widget.timetableEntry.lesson);
    String end = SubstituteDTO.lessonEnd(widget.timetableEntry.lesson);
    String suffix = AppLocalizations.of(context)!.oclock;

    return "$start - $end $suffix";
  }

  TimetableEntry? saveChanges() {
    if (!_editing) return null;

    return dataService.updateTimetable(
      day: widget.date.weekday,
      lesson: widget.timetableEntry.lesson,
      subjectId: _subject?.subjectId,
      className: _classNameController.text.nullIfBlank,
      teacher: _teacherController.text.nullIfBlank,
      room: _roomController.text.nullIfBlank,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.timetableEntry.className != null) {
      _classNameController.text = widget.timetableEntry.className!;
    }
    if (widget.timetableEntry.teacher != null) {
      _teacherController.text = widget.timetableEntry.teacher!;
    }
    if (widget.timetableEntry.className != null) {
      _roomController.text = widget.timetableEntry.room!;
    }

    return WillPopScope(
      onWillPop: () async {
        saveChanges();
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
              onPressed: () {
                saveChanges();
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            if (_editing)
              IconButton(
                icon: const Icon(Icons.delete),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () {
                  _classNameController.clear();
                  _teacherController.clear();
                  _roomController.clear();
                  _subject = null;
                  saveChanges();
                  Navigator.pop(context);
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
                    saveChanges();

                    _editing = !_editing;
                  });
                },
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              ListTile(
                leading: Hero(
                  tag: widget.heroTag,
                  child: SizedBox.square(
                    dimension: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _subjectColor(context, _subject),
                      ),
                    ),
                  ),
                ),
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _subjectName(context, _subject),
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
                        Subject? res = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SelectSubjectPage()),
                        );
                        if (res != null && res.subjectId != _subject?.subjectId) {
                          setState(() {
                            _subject = res;
                          });
                        }
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                dense: true,
                title: Text(
                  widget.timetableEntry.lesson.toString(),
                  style: const TextStyle(fontSize: 18),
                ),
                subtitle: Text(_timeOfLessons()),
              ),
              if (!_classNameController.text.isBlank || _editing)
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
              if (!_teacherController.text.isBlank || _editing)
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
              if (_editing)
                Visibility(
                  visible: false, //TODO change to view
                  child: Disabled(
                    disabled: _subject?.subjectId == null,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
                            ),
                            foregroundColor: MaterialStateProperty.all(
                              Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Text(
                              AppLocalizations.of(context)!.copy,
                              textScaleFactor: 1.1,
                            ),
                          ),
                          onPressed: () {
                            //TODO copy timetable entries
                          },
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Select a subject from a list. Returns subject or null of aborted.
class SelectSubjectPage extends StatelessWidget {
  const SelectSubjectPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var subjects = context.data<SubjectService>()!.getAllSubjects();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.pickSubject),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(
            Icons.clear,
            color: Colors.grey,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        itemBuilder: (context, index) => ListTile(
          leading: Center(
            widthFactor: 1,
            child: SizedBox.square(
              dimension: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: subjects[index].parsedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          title: Text(
            subjects[index].parsedName(context),
            textScaleFactor: 1.2,
          ),
          onTap: () => Navigator.pop(context, subjects[index]),
        ),
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Divider(height: 4, thickness: 2),
        ),
        itemCount: subjects.length,
      ),
    );
  }
}
