/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/grades.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/extended_page_with_subject.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';

class ExtendedGradePage extends CompactStatefulWidget {
  const ExtendedGradePage({
    super.key,
    this.grade,
    this.subject,
    this.heroTag,
  });

  final Document<Grade>? grade;
  final Document<Subject>? subject;
  final String? heroTag;

  @override
  State<ExtendedGradePage> createState() => _ExtendedGradePageState();
}

class _ExtendedGradePageState extends State<ExtendedGradePage> {

  DateTime? date;
  int? gradeType;

  GlobalKey<GradeSliderState> gradeSliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    date = widget.grade?.data?.created ?? DateTime.now();
    gradeType = widget.grade?.data?.gradeType;
  }

  @override
  Widget build(BuildContext context) {
    var subjectDoc = widget.grade?.data?.subject.defaultStorage(context);
    subjectDoc ??= widget.subject;

    return StreamConsumer<Grades>(
      doc: Grades.ref().defaultStorage(context),
      itemBuilder: (context, doc, grades) {
        return ExtendedPageWithSubject(
          editing: true,
          heroTag: widget.heroTag,
          subject: subjectDoc,
          onDelete: widget.grade == null ? null : () {
            widget.grade?.delete();
            context.pop();
          },
          onEdit: (edit, subject) {
            if (subject == null || gradeType == null) return false;

            var usePoints = grades.usePoints;
            var value = gradeSliderKey.currentState!.value;

            //If grade was not provided create new
            if (widget.grade == null) {
              Grades.entries().defaultStorage(context).addDocument(Grade(
                    subject: subject,
                    gradeType: gradeType!,
                    created: date!,
                    points: usePoints ? value : Grade.gradeToPoints(value),
                  ));
            } else {
              var grade = widget.grade!.data!;
              bool markForFlush = false;

              //If date has changed update
              if (date != null && grade.created != date) {
                grade.created = date!;

                markForFlush = true;
              }

              //If grade type has changed update
              if (gradeType != null && grade.gradeType != gradeType) {
                grade.gradeType = gradeType!;

                markForFlush = true;
              }

              //If grade value has changed update
              var oldPoints = grade.points;
              var newPoints = usePoints ? value : Grade.gradeToPoints(value);
              if (oldPoints != newPoints) {
                grade.points = newPoints;

                markForFlush = true;
              }

              //Perform actual update
              if (markForFlush) widget.grade!.setDelayed(grade);
            }

            context.pop();

            return true;
          },
          children: (edit, subject) => [
              ListTile(
                dense: true,
                leading: const Icon(Icons.today),
                title: ElevatedButton(
                  onPressed: () async {
                    var date = await context.dialog(DatePickerDialog(
                      firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                      initialDate: DateTime.now(),
                      lastDate: DateTime.now(),
                    ));
                    if (date == null) return;

                    setState(() => this.date = date);
                  },
                  child: Text(date!.formatEEEEddMM(context)).fontSize(18),
                ),
              ),
              ListTile(
                title: ElevatedButton(
                  onPressed: subject == null
                      ? null
                      : () async {
                          String? groupValue;
                          var gradeType = await context.dialog(AlertDialog(
                            content: SizedBox(
                              width: 300,
                              child: ListView(
                                shrinkWrap: true,
                                children: subject.getGradeTypes(context).mapIndex((gradeType, i) {
                                  return ListTile(
                                    title: Text(gradeType.name),
                                    onTap: () => context.pop(result: i),
                                    leading: Radio<String>(
                                      value: gradeType.name,
                                      groupValue: groupValue,
                                      onChanged: (value) => context.pop(result: i),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ));
                          if (gradeType == null) return;

                          this.gradeType = gradeType;
                          setState(() {});
                        },
                  child: Text(
                    (gradeType != null ? subject?.getGradeTypes(context)[gradeType!].name : null) ??
                        context.l10n.selectGradeType,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                leading: const Icon(Icons.style),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: context.pop,
                ),
              ),
              GradeSlider(
                key: gradeSliderKey,
                color: subject?.parsedColor,
                value: () {
                  var points = widget.grade?.data?.points;
                  if (points == null) return null;

                  return grades.usePoints ? points : Grade.pointsToGrade(points);
              }.call(),
              )
            ],
        );
      },
    );
  }
}

num gradeToValue(num grade) => grade * -1 + 7;

num valueToGrade(num value) => (value - 7) * -1;

class GradeSlider extends StatefulWidget {
  const GradeSlider({super.key, required this.color, this.value});

  final int? value;
  final Color? color;

  @override
  State<GradeSlider> createState() => GradeSliderState();
}

class GradeSliderState extends State<GradeSlider> {
  /// Value of the actual slider
  double? _sliderValue;

  /// Value that is shown
  int? _value;

  int get value => _value!;

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<Grades>(
      doc: Grades.ref().defaultStorage(context),
      itemBuilder: (context, doc, grades) {
        return StatefulBuilder(
          builder: (context, setState) {
            var usePoints = grades.usePoints;
            var divisions = usePoints ? 15 : 5;

            if (widget.value == null) {
              _sliderValue ??= usePoints ? 5 : 3;
            } else {
              var value = widget.value!.toDouble();
              _sliderValue ??= usePoints ? value : gradeToValue(value).toDouble();
            }

            _value = (usePoints ? _sliderValue! : gradeToValue(_sliderValue!)).toInt();

            return ListTile(
              minVerticalPadding: 8,
              leading: const Icon(Icons.assessment),
              title: Slider(
                value: _sliderValue!,
                min: usePoints ? 0 : 1,
                divisions: divisions,
                max: divisions + (usePoints ? 0 : 1),
                label: value.toInt().toString(),
                activeColor: widget.color,
                onChanged: (value) {
                  setState(() => _sliderValue = value);
                  _value = (usePoints ? value : gradeToValue(value)).toInt();
                },
              ),
            );
          },
        );
      },
    );
  }
}
