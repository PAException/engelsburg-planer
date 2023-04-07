/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */
import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/extended_subject.dart';
import 'package:engelsburg_planer/src/view/widgets/extended_page_with_subject.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';

class ExtendedGradePage extends CompactStatefulWidget {
  const ExtendedGradePage({
    Key? key,
    this.grade,
    this.subject,
    this.heroTag,
    this.pushedFromSubjectPage = false,
  }) : super(key: key);

  final Document<Grade>? grade;
  final Document<Subject>? subject;
  final String? heroTag;
  final bool pushedFromSubjectPage;

  @override
  State<ExtendedGradePage> createState() => _ExtendedGradePageState();
}

class _ExtendedGradePageState extends State<ExtendedGradePage> {
  DateTime? date;
  int? gradeType;

  GlobalKey<_GradeSliderState> gradeSliderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    date = widget.grade?.data?.created ?? DateTime.now();
    gradeType = widget.grade?.data?.gradeType;
  }

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<Grades>(
      doc: Grades.get(),
      builder: (context, doc, grades) {
        return ExtendedPageWithSubject(
          editing: true,
          subject: widget.grade?.data?.subject ?? widget.subject,
          heroTag: widget.heroTag,
          onEdit: (edit, subject) {
            if (subject == null || gradeType == null) return false;

            var usePoints = grades.usePoints;
            var gradeOrPoints = gradeSliderKey.currentState!.value;

            if (widget.grade == null) {
              Grades.get().entries.add(Grade(
                    subject: subject,
                    gradeType: gradeType!,
                    created: date!,
                    points: usePoints ? gradeOrPoints : null,
                    grade: usePoints ? null : gradeOrPoints,
                  ));
            } else {
              var grade = widget.grade!;
              bool markForFlush = false;

              if (date != null && grade.data!.created != date) {
                grade.data!.created = date!;
                markForFlush = true;
              }
              if (gradeType != null && grade.data!.gradeType != gradeType) {
                grade.data!.gradeType = gradeType!;
                markForFlush = true;
              }

              var oldValue = grade.data!.value(usePoints);
              var newValue = gradeSliderKey.currentState!.value;
              if (oldValue != newValue && (grade.data!.points != null && usePoints)) {
                grade.data!.grade = usePoints ? null : newValue;
                grade.data!.points = usePoints ? newValue : null;

                markForFlush = true;
              }

              if (markForFlush) grade.flush();
            }
            context.pop();

            return false;
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
                              children:
                                  subject.data!.getGradeTypes(context).mapIndex((gradeType, i) {
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
                  (gradeType != null ? subject?.data?.gradeTypes[gradeType!].name : null) ??
                      context.l10n.selectGradeType,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              leading: const Icon(Icons.style),
              trailing: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: subject == null
                    ? null
                    : (widget.pushedFromSubjectPage
                        ? context.pop
                        : () => context.pushPage(ExtendedSubjectPage(subject: subject))),
              ),
            ),
            GradeSlider(
              key: gradeSliderKey,
              color: subject?.data?.parsedColor,
              value: widget.grade?.data?.value(grades.usePoints),
            )
          ],
        );
      },
    );
  }
}

class GradeSlider extends StatefulWidget {
  const GradeSlider({Key? key, required this.color, this.value}) : super(key: key);

  final int? value;
  final Color? color;

  @override
  State<GradeSlider> createState() => _GradeSliderState();
}

class _GradeSliderState extends State<GradeSlider> {
  double? _sliderValue;
  int? _divisions;

  int get value => _sliderValue!.toInt();

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<Grades>(
      doc: Grades.get(),
      builder: (context, doc, grades) {
        var usePoints = grades.usePoints;
        _sliderValue ??= widget.value?.toDouble() ?? (usePoints ? 5 : 4);
        _divisions ??= usePoints ? 15 : 5;

        return ListTile(
          minVerticalPadding: 8,
          leading: const Icon(Icons.assessment),
          title: Slider(
            value: _sliderValue!,
            min: usePoints ? 0 : 1,
            divisions: _divisions!,
            max: _divisions! + (usePoints ? 0 : 1),
            label: (usePoints ? _sliderValue! : _sliderValue! * -1 + 7).toInt().toString(),
            activeColor: widget.color,
            onChanged: (value) {
              _sliderValue = value;
              setState(() {});
            },
          ),
        );
      },
    );
  }
}
