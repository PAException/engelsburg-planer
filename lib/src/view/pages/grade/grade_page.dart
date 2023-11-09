/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:d_chart/commons/axis.dart';
import 'package:d_chart/commons/config_render.dart';
import 'package:d_chart/commons/data_model.dart';
import 'package:d_chart/commons/decorator.dart';
import 'package:d_chart/commons/enums.dart';
import 'package:d_chart/commons/style.dart';
import 'package:d_chart/commons/viewport.dart';
import 'package:d_chart/ordinal/bar.dart';
import 'package:d_chart/time/line.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/grades.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/grade/grade_average_circle.dart';
import 'package:engelsburg_planer/src/view/pages/grade/grade_extended.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_extended.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_collection.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';

class GradesPage extends StatelessWidget {
  const GradesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamCollection<Subject>(
      collection: Subjects.entries().defaultStorage(context),
      itemBuilder: (context, doc, subjects) {
        return StreamCollection<Grade>(
          collection: Grades.entries().defaultStorage(context),
          itemBuilder: (context, collection, grades) {
            return StreamConsumer<Grades>(
              doc: Grades.ref().defaultStorage(context),
              itemBuilder: (context, doc, config) {
                Map<String, double> averages = {};
                Map<String, List<double>> subjectTypeAverages = {};

                for (var subject in subjects) {
                  //Get grades of current subject
                  var filteredGrades = grades
                      .where((grade) => grade.data!.subject == subject)
                      .toList();

                  //Sort grades by type
                  Map<int, List<Document<Grade>>> gradesByType = {};
                  for (var grade in filteredGrades) {
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
                      typeAverage += grade.value(config.usePoints) *
                          (1 / gradesWithType.length);
                    }
                    if (gradesWithType.isNotEmpty) {
                      typeAverages[key] = typeAverage;
                    }
                  }
                  var gradeTypes = subject.data!.getGradeTypes(context);
                  typeAverages
                      .removeWhere((key, value) => key > gradeTypes.length - 1);

                  if (typeAverages.isNotEmpty) {
                    var average = typeAverages.length < 2
                        ? typeAverages.values.first
                        : typeAverages.entries.fold<double>(
                            0,
                            (pre, e) =>
                                pre + e.value * gradeTypes[e.key].share);

                    subjectTypeAverages[subject.id] =
                        typeAverages.values.toList();
                    averages[subject.id] = average;
                  }
                }

                double globalAverage = 0;
                double globalPercent = 0;
                if (averages.isNotEmpty) {
                  globalAverage =
                      averages.values.reduce((v, e) => v + e) / averages.length;
                  if (config.usePoints) {
                    globalPercent = globalAverage / 15;
                  } else {
                    globalPercent = -(globalAverage / 5) + 1.2;
                  }
                }

                return Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    heroTag: StringUtils.randomAlphaNumeric(10),
                    label: Text(context.l10n.addGrade),
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        context.pushPage(const ExtendedGradePage()),
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
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  config.usePoints = !config.usePoints;
                                  doc.setDelayed(config);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  alignment: Alignment.topRight,
                                  child: Icon(
                                    config.usePoints
                                        ? Icons.assessment_outlined
                                        : Icons.assessment,
                                    size: 32,
                                  ),
                                ),
                              ),
                              Center(
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AverageGradeCircle(
                                    average: globalAverage,
                                    percent: globalPercent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );

                    var subjectList = grades.isNotEmpty
                        ? Card(
                            child: ListView(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              children: subjects
                                  .where((e) => averages.containsKey(e.id))
                                  .map((subject) {
                                return ListTile(
                                  horizontalTitleGap: 0,
                                  leading: Container(
                                    alignment: Alignment.center,
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      color: subject.data!.parsedColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  onTap: () => context.pushPage(
                                      ExtendedSubjectPage(subjectDoc: subject)),
                                  title: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          subject.data!.parsedName(context),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      context.mediaQuerySize.width <= 200
                                          ? Container()
                                          : Text(
                                              subjectTypeAverages[subject.id]!
                                                  .map(
                                                      (e) => e.roundToPlaces(2))
                                                  .join(" - "),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      context.mediaQuerySize.width <= 200
                                          ? Container()
                                          : const Flex(
                                              direction: Axis.horizontal),
                                      const SizedBox(width: 12),
                                      Text(
                                        averages[subject.id]!
                                            .roundToPlaces(2)
                                            .toString(),
                                        textAlign: TextAlign.right,
                                        textScaleFactor: 1,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      )
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
                              height: 30 + averages.values.length * 70,
                              width: 400,
                              child: DChartBarO(
                                animate: true,
                                vertical: false,
                                flipVertical: !config.usePoints,
                                barLabelDecorator: BarLabelDecorator(
                                  barLabelPosition: BarLabelPosition.auto,
                                  labelAnchor: BarLabelAnchor.end,
                                ),
                                insideBarLabelStyle: (_, data, ___) =>
                                    LabelStyle(
                                  fontSize: 16,
                                  color: data.color!.computeLuminance() > 0.5
                                      ? ThemeData.dark()
                                          .textTheme
                                          .bodyMedium!
                                          .color!
                                      : ThemeData.light()
                                          .textTheme
                                          .bodyMedium!
                                          .color!,
                                ),
                                barLabelValue: (_, ordinalData, __) {
                                  var measure = ordinalData.measure as double;

                                  return (config.usePoints
                                          ? measure
                                          : valueToGrade(measure))
                                      .round()
                                      .toString();
                                },
                                fillColor: (_, ordinalData, __) =>
                                    ordinalData.color,
                                measureAxis: MeasureAxis(
                                  labelStyle: LabelStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color!,
                                  ),
                                  desiredTickCount: config.usePoints ? 6 : null,
                                  labelFormat: (measure) {
                                    var value = config.usePoints
                                        ? measure!
                                        : valueToGrade(measure!);
                                    if (!config.usePoints && value > 6) {
                                      return "";
                                    }

                                    return value.toInt().toString();
                                  },
                                  numericViewport: !config.usePoints
                                      ? null
                                      : const NumericViewport(
                                          //Bug: https://github.com/indratrisnar/d_chart/pull/20#issue-1936347727
                                          0,
                                          15,
                                        ),
                                ),
                                groupList: [
                                  OrdinalGroup(
                                    id: "Bar",
                                    data: averages.mapToList((key, value) {
                                      var subject = subjects
                                          .firstWhere((e) => e.id == key);
                                      var domain =
                                          subject.data!.parsedName(context);

                                      return OrdinalData(
                                        domain: domain.length > 14
                                            ? "${domain.substring(0, 12)}..."
                                            : domain,
                                        measure: config.usePoints
                                            ? value
                                            : gradeToValue(value),
                                        color: subject.data!.parsedColor,
                                      );
                                    }),
                                  ),
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
                              child: DChartLineT(
                                animate: true,
                                flipVertical: !config.usePoints,
                                configRenderLine: ConfigRenderLine(
                                  includePoints: true,
                                  strokeWidthPx: 4,
                                  radiusPx: 4.5,
                                ),
                                measureAxis: MeasureAxis(
                                  thickLength: 1,
                                  showLine: true,
                                  labelFormat: (value) =>
                                      value!.toInt().toString(),
                                  labelStyle: LabelStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color!,
                                  ),
                                ),
                                domainAxis: DomainAxis(
                                  labelFormatterT: (dateTime) =>
                                      dateTime.format(context, "dd.MM."),
                                  numericViewport: NumericViewport(
                                    config.usePoints ? 0 : 6,
                                    config.usePoints ? 15 : 1,
                                  ),
                                  labelStyle: LabelStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .color!,
                                  ),
                                ),
                                groupList: subjects.map((subject) {
                                  var filtered = grades
                                      .map((e) => e.data!)
                                      .map((e) =>
                                          e..created = e.created.roundToDay())
                                      .where(
                                          (grade) => grade.subject == subject)
                                      .toList();

                                  Map<DateTime, double> average = {};
                                  for (int i = 0; i < filtered.length; i++) {
                                    var grade = filtered[i];
                                    var same = filtered.where((other) =>
                                        other.created == grade.created);
                                    if (same.length <= 1) {
                                      average[grade.created] =
                                          grade.points.toDouble();
                                      continue;
                                    }

                                    var sum = List.of(same).fold(
                                      0,
                                      (value, element) {
                                        return value + element.points;
                                      },
                                    );
                                    average[grade.created] = sum / same.length;
                                  }

                                  return TimeGroup(
                                    id: subject.data!.parsedName(context),
                                    color: subject.data!.parsedColor,
                                    data: average.mapToList((date, points) {
                                      return TimeData(
                                        domain: date,
                                        measure: config.usePoints
                                            ? points
                                            : Grade.pointsToGrade(
                                                points.toInt()),
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

                    return ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 500,
                        minHeight: 200,
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        shrinkWrap: true,
                        children: [
                          averageCircle,
                          subjectList,
                          averageSubjectChart,
                          subjectDevelopmentChart,
                          if (averages.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: ElevatedButton(
                                  onPressed: () => context.pushPage(const ExtendedGradePage()),
                                  child: Text(context.l10n.add),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                );
              },
            );
          },
        );
      },
    );
  }
}
