/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/controller/timetable_controller.dart';
import 'package:engelsburg_planer/src/models/api/dto/substitute_dto.dart';
import 'package:engelsburg_planer/src/models/api/timetable.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/widgets/timetable_card.dart';
import 'package:engelsburg_planer/src/view/widgets/util/advanced_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:week_of_year/week_of_year.dart';

const _kDuration = Duration(milliseconds: 500);

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => TimetablePageState();
}

class TimetablePageState extends State<TimetablePage> with DataStateMixin<TimetableService> {
  late final ScrollController _scrollController;
  final _animatedList = GlobalKey<AdvancedAnimatedListState>();

  late Future<List<TimetableEntry>> _fetch;
  List<Widget> _timetable = [];
  DateTime _date = DateTime.now();
  bool _overScrolling = false;
  bool _edit = false;

  /// Refresh the page: Animate removal and insertion of the timetable
  /// If no date specified use [_date]
  Future<void> refresh([DateTime? date, bool fast = false]) async {
    //Request async fetch
    _fetch = dataService.getTimetable(date ?? _date);

    //Remove all
    _timetable.forIndexed(
      (index, element) {
        _timetable.removeAt(index);
        _animatedList.currentState?.removeItem(
          index,
          (context, animation) => Animations.easeFade(animation, element),
          duration: fast ? Duration.zero : _kDuration,
        );
      },
      reverse: true,
    );

    //Wait for animation to complete, reset scroll and build timetable
    await Future.delayed(fast ? Duration.zero : _kDuration);
    _scrollController.jumpTo(0);
    _timetable = _buildTimetable((await _fetch));

    //Insert all
    await _timetable.forIndexed(
      (index, element) async {
        _animatedList.currentState?.insertItem(
          index,
          duration: _kDuration * (fast ? 0.75 : 1),
          builder: (context, animation) => Animations.easeOutScaleQuadSize(animation, element),
        );
        await Future.delayed(_kDuration ~/ (fast ? 30 : 20));
      },
    );
  }

  @override
  void initState() {
    super.initState();

    //Init scrollController to trigger function on overScroll
    _scrollController = ScrollController()
      ..addListener(
        () {
          var max = _scrollController.position.maxScrollExtent;
          if (_scrollController.position.extentAfter - max > 100) {
            _overScroll(true);
          } else if (_scrollController.position.extentBefore - max > 100) {
            _overScroll(false);
          }
        },
      );

    //Initiate async fetch of timetable
    _fetch = dataService.getTimetable(_date);
  }

  /// Shortcut to animate the removal of an element in _toggleEdit()
  void _animatedListEditRemove(int index, Widget element) {
    //Remove element from list with same animation
    _animatedList.currentState?.removeItem(
      index,
      (context, animation) => Animations.easeInOutSineSizeEaseInSineScale(
        animation,
        element,
      ),
      duration: _kDuration,
    );
  }

  /// Trigger transition between dates
  void _dateEditTransition(Widget from, Widget to) {
    //Remove date
    _timetable.remove(from);
    _animatedList.currentState?.removeItem(
      0,
      (context, animation) => Animations.easeFadeScaleSize(animation, from),
      duration: Duration.zero,
    );

    //Insert new
    _timetable.insert(0, to);
    _animatedList.currentState?.insertItem(
      0,
      builder: (context, animation) => Animations.easeInOutSineSizeEaseInSineScale(animation, to),
      duration: _kDuration,
    );
  }

  /// Executed if you want or no more want to edit the timetable
  Future<void> _toggleEdit() async {
    if (_overScrolling) return;
    setState(() => _edit = !_edit);

    //Update timetable and build
    _fetch = dataService.getTimetable(_date);
    List<Widget> newEntries = _buildTimetable((await _fetch));

    if (_edit) {
      //Date transition
      _dateEditTransition(_timetable[0], newEntries[0]);

      //Remove no entries if present
      if (_timetable[1] is TimetableNoEntries) {
        final toRemove = _timetable[1];
        _timetable.removeAt(1);
        _animatedListEditRemove(1, toRemove);
      }

      newEntries.forIndexed((index, newEntry) {
        //Skip date
        if (index == 0) return;

        Widget? old = _timetable.nullableAt(index);

        //Remove if free hour
        if (old is TimetableFreeHour) {
          _timetable.remove(old);
          _animatedListEditRemove(index, old);

          //Insert newEntry
          _timetable.insert(index, newEntry);
          _animatedList.currentState?.insertItem(index);
          return;
        }

        //Insert if no old lesson but new lesson
        //Insert if old is break and new is lesson
        //Insert if old is lesson and new is break
        //Insert if old lesson is higher than new lesson
        if (old == null ||
            (old is TimetableBreak && newEntry is TimetableCard) ||
            (old is TimetableCard && newEntry is TimetableBreak) ||
            (old is TimetableCard &&
                newEntry is TimetableCard &&
                old.entry.lesson > newEntry.entry.lesson)) {
          _timetable.insert(index, newEntry);
          _animatedList.currentState?.insertItem(index);
        }
      });
    } else {
      //If new has no entries delete all except date and insert noEntries
      if (newEntries[1] is TimetableNoEntries) {
        //Date transition
        _dateEditTransition(_timetable[0], newEntries[0]);

        for (int index = 1; index < _timetable.length;) {
          final element = _timetable[index];
          _timetable.remove(element);
          _animatedListEditRemove(index, element);
        }

        //Insert noEntries
        _timetable.insert(1, newEntries[1]);
        _animatedList.currentState?.insertItem(1, duration: _kDuration);
        return;
      }

      for (int index = 0; index < _timetable.length; index++) {
        Widget old = _timetable[index];
        Widget? newEntry = newEntries.nullableAt(index);

        //Date transition
        if (index == 0) {
          _dateEditTransition(old, newEntry!);
          continue;
        }

        //Insert if new is free hour
        if (newEntry is TimetableFreeHour) {
          _timetable.insert(index, newEntry);
          _animatedList.currentState?.insertItem(index);
          continue;
        }

        //Remove if old but no new lesson
        //Remove if old is break and new is lesson
        //Remove if old lesson is lower than new
        if (newEntry == null ||
            (old is TimetableBreak && newEntry is TimetableCard) ||
            (old is TimetableCard && old.entry.lesson < (newEntry as TimetableCard).entry.lesson)) {
          _timetable.remove(old);
          _animatedListEditRemove(index, old);
          index--;
        }
      }
    }
  }

  /// Executed if overScroll happened to show next or last day
  Future<void> _overScroll(bool back) async {
    //Lock overScroll
    if (_overScrolling) return;
    _overScrolling = true;

    //Add or subtract one day as long as the result is on a weekend
    const day = Duration(days: 1);
    do {
      if (back) {
        _date = _date.subtract(day);
      } else {
        _date = _date.add(day);
      }
    } while (_date.weekday == DateTime.saturday || _date.weekday == DateTime.sunday);

    //Refresh with new date
    await refresh();

    //Unlock
    _overScrolling = false;
  }

  /// Return string with calendar week and date of monday to friday (e.g. "CW 15 (11.04. - 15.04.)")
  String _getSubtitle() {
    DateTime date = _date;
    DateFormat dateFormat = DateFormat(
      "dd.MM.",
      Localizations.localeOf(context).languageCode,
    );

    //Subtract date to monday
    date = date.subtract(Duration(days: date.weekday - 1));

    String cwAbr = AppLocalizations.of(context)!.calendarWeekAbr;
    int cw = date.weekOfYear;
    String mon = dateFormat.format(date);
    String fri = dateFormat.format(date.add(const Duration(days: 4)));

    return "$cwAbr $cw ($mon - $fri)";
  }

  /// Select a date to jump to
  void _selectDate() async {
    if (_overScrolling) return;

    //Show ui to pick date
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2022),
      lastDate: DateTime(10000000),
      confirmText: AppLocalizations.of(context)!.ok,
      cancelText: AppLocalizations.of(context)!.cancel,
      helpText: AppLocalizations.of(context)!.pickDate,
    );

    //If a date was selected and is not the current then set it as the current and jump to
    if (date != null && date != _date) {
      _date = date;
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _selectDate,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.timetable,
                          textScaleFactor: 2,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            _getSubtitle(),
                            textScaleFactor: 1.2,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: Container()),
                IconButton(
                  onPressed: () {
                    if (_overScrolling) return;

                    //Only skip to current date if date is not already today
                    if (!_date.isSameDay(DateTime.now())) {
                      _date = DateTime.now();
                      refresh();
                    }
                  },
                  icon: const Icon(Icons.today),
                ),
                IconButton(
                  onPressed: _toggleEdit,
                  icon: Icon(_edit ? Icons.done : Icons.edit_outlined),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 4, bottom: 8),
              child: Divider(height: 10, thickness: 3),
            ),
            FutureBuilder<List<TimetableEntry>>(
              future: _fetch,
              builder: (context, snapshot) {
                //If no data available yet return loading
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                //Build timetable only once on first build
                //Otherwise it will conflict with other assignations from e.g. toggleEdit
                if (_timetable.isEmpty) _timetable = _buildTimetable(snapshot.data!);

                //Build ListView
                return Expanded(
                  child: AdvancedAnimatedList(
                    key: _animatedList,
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    initialItemCount: _timetable.length,
                    itemBuilder: (context, index, animation) =>
                        Animations.easeInOutSineSizeEaseInSineScale(
                      animation,
                      _timetable[index],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );

  /// Build the timetable as Widgets out of timetableEntries
  List<Widget> _buildTimetable(List<TimetableEntry> timetable) {
    //Create list cards with TimetableDate as first element
    List<Widget> cards = [TimetableDate(date: _date, editing: _edit)];

    //Copy timetable
    List<TimetableEntry> entries = List.of(timetable..sort());

    //If edit mode then fill all entries with blank cards
    if (_edit) {
      for (var i = 1; i <= 13; i++) {
        if (!entries.any((element) => element.lesson == i)) {
          entries.insert(i - 1, TimetableEntry(lesson: i, day: _date.weekday));
        }
      }
    }

    //Iterate through entries to get timetable cards
    var lastLesson = -1;
    for (var entry in entries) {
      //If lesson difference than insert TimetableFreeHour
      //If index is break insert TimetableBreak
      var lessonDiff = entry.lesson - lastLesson;
      if (lessonDiff > 1 && lastLesson != -1) {
        String start = SubstituteDTO.lessonEnd(lastLesson);
        String end = SubstituteDTO.lessonStart(entry.lesson);

        var card = TimetableFreeHour(
          freeHours: lessonDiff - 1,
          timeSpan: "$start - $end ${AppLocalizations.of(context)!.oclock}",
        );
        cards.add(card);
      } else if ((entry.lesson == 3 || entry.lesson == 5) && lastLesson != -1) {
        cards.add(const TimetableBreak());
      }

      //Create and add the card
      var card = TimetableCard(
        entry: entry,
        date: _date,
        refreshCallback: () => refresh(null, true),
        editing: _edit,
      );
      cards.add(card);

      //Set last lesson to calculate lesson difference in next iteration
      lastLesson = entry.lesson;
    }

    //If no cards were added except the date insert TimetableNoEntries
    if (cards.length == 1) {
      cards.add(TimetableNoEntries(editCallback: _toggleEdit));
    }

    return cards;
  }
}
