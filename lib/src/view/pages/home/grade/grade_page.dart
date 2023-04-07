/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:d_chart/d_chart.dart';
import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/home/grade/average_grade_circle.dart';
import 'package:engelsburg_planer/src/view/pages/home/grade/extended_grade.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/extended_subject.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  List<Document<Subject>> subjects = [];
  List<Document<Grade>> grades = [];

  List<StreamSubscription> subs = [];

  @override
  void initState() {
    super.initState();
    subs = [
      Grades.get().entries.snapshots().listen((event) => setState(() => grades = event)),
      Subjects.get().entries.snapshots().listen((event) => setState(() => subjects = event)),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    for (var element in subs) {
      element.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<Grades>(
      doc: Grades.get(),
      builder: (context, doc, config) {
        Map<String, double> averages = {};
        Map<String, List<double>> subjectTypeAverages = {};

        for (var subject in subjects) {
          //Get grades of current subject
          var grades = this.grades.where((grade) => grade.data!.subject == subject).toList();

          //Sort grades by type
          Map<int, List<Document<Grade>>> gradesByType = {};
          for (var grade in grades) {
            var typeIndex = grade.data!.gradeType;
            var gradesWithType = gradesByType[typeIndex] ?? [];

            gradesByType[typeIndex] = gradesWithType..add(grade);
          }

          //Get averages of each type
          Map<int, double> typeAverages = {};
          for (var key in gradesByType.keys) {
            var gradesWithType = gradesByType[key]!;

            double typeAverage = 0;
            for (var grade in gradesWithType.map((e) => e.data!)) {
              typeAverage += grade.value(config.usePoints) * (1 / gradesWithType.length);
            }
            if (typeAverage != 0) typeAverages[key] = typeAverage;
          }
          typeAverages.removeWhere((key, value) => key > subject.data!.gradeTypes.length - 1);

          if (typeAverages.isNotEmpty) {
            var average = typeAverages.length < 2
                ? typeAverages.values.first
                : typeAverages.entries.fold<double>(0,
                    (pre, e) => pre + e.value * subject.data!.getGradeTypes(context)[e.key].share);

            subjectTypeAverages[subject.id] = typeAverages.values.toList();
            averages[subject.id] = average;
          }
        }

        double globalAverage = 0;
        double globalPercent = 0;
        if (averages.isNotEmpty) {
          globalAverage = averages.values.reduce((v, e) => v + e) / averages.length;
          if (config.usePoints) {
            globalPercent = globalAverage / 15;
          } else {
            globalPercent = -(globalAverage / 5) + 1.2;
          }
        }

        return Scaffold(
          floatingActionButton: FloatingActionButton(
            heroTag: StringUtils.randomAlphaNumeric(10),
            child: const Icon(Icons.add_circle),
            onPressed: () => context.pushPage(const ExtendedGradePage()),
          ),
          body: LayoutBuilder(builder: (context, constraints) {
            var landscape = constraints.maxWidth > 800;

            var averageCircle = Card(
              child: WrapIf(
                condition: landscape && grades.isNotEmpty,
                wrap: (child, context) => AspectRatio(
                  aspectRatio: 3 / 2,
                  child: child,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: AverageGradeCircle(
                    average: globalAverage,
                    percent: globalPercent,
                  ),
                ),
              ),
            );

            var subjectList = grades.isNotEmpty
                ? Card(
                    child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      children: subjects.where((e) => averages.containsKey(e.id)).map((subject) {
                        return ListTile(
                          horizontalTitleGap: 0,
                          trailing: SizedBox(
                            width: 80,
                            child: Text(
                              averages[subject.id]!.roundToPlaces(2).toString(),
                              textAlign: TextAlign.right,
                              textScaleFactor: 1.4,
                            ),
                          ),
                          leading: Container(
                            alignment: Alignment.center,
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              color: subject.data!.parsedColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onTap: () => context.pushPage(ExtendedSubjectPage(subject: subject)),
                          title: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  subject.data!.parsedName(context),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              context.mediaQuerySize.width > 400
                                  ? Flexible(
                                      flex: 1,
                                      child: Text(
                                        subjectTypeAverages[subject.id]!
                                            .map((e) => e.roundToPlaces(2))
                                            .join(" - "),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : Container();

            var averageSubjectChart = grades.isNotEmpty
                ? Card(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      height: 30 + averages.values.where((e) => e != 0).length * 70,
                      width: 400,
                      child: DChartBar(
                        animate: true,
                        barValue: (data, _) => "${(data["measure"] as double).round()}  ",
                        showBarValue: true,
                        barValuePosition: BarValuePosition.inside,
                        barValueFontSize: 16,
                        barValueAnchor: BarValueAnchor.end,
                        verticalDirection: false,
                        measureMax: 15,
                        measureMin: 0,
                        barColor: (barData, index, id) => barData["color"],
                        data: [
                          {
                            'id': 'Bar',
                            'data': averages.mapToList((key, value) {
                              var subject = subjects.firstWhere((e) => e.id == key);
                              var domain = subject.data!.parsedName(context);
                              return {
                                "domain":
                                    domain.length > 12 ? "${domain.substring(0, 12)}..." : domain,
                                "measure": value,
                                "color": subject.data!.parsedColor,
                              };
                            }),
                          },
                        ],
                      ),
                    ),
                  )
                : Container();

            var subjectDevelopmentChart = grades.isNotEmpty
                ? Card(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      height: 400,
                      child: DChartTime(
                        measureTickLength: 1,
                        animate: true,
                        measureLabel: (value) => value!.toInt().toString(),
                        flipVerticalAxis: !config.usePoints,
                        chartRender: DRenderLine(showPoint: true),
                        domainLabel: (dateTime) => dateTime!.format(context, "dd.MM."),
                        endDate: DateTime.now(),
                        startFromZero: true,
                        groupData: subjects.map((subject) {
                          var grades =
                              this.grades.where((grade) => grade.data!.subject == subject).toList()
                                ..sort(
                                  (a, b) => a.data!.created.millisecondsSinceEpoch >
                                          b.data!.created.millisecondsSinceEpoch
                                      ? 1
                                      : -1,
                                );

                          return DChartTimeGroup(
                            id: subject.data!.parsedName(context),
                            color: subject.data!.parsedColor,
                            data: grades.map((grade) {
                              return DChartTimeData(
                                time: grade.data!.created.roundToDay(),
                                value: grade.data!.value(config.usePoints),
                              );
                            }).toList(),
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : Container();

            if (landscape && constraints.maxWidth > 500) {
              return SingleChildScrollView(
                child: Container(
                  alignment: Alignment.topCenter,
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            averageCircle,
                            subjectList,
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            averageSubjectChart,
                            subjectDevelopmentChart,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400, minHeight: 200),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  children: [
                    averageCircle,
                    subjectList,
                    averageSubjectChart,
                    subjectDevelopmentChart,
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
