/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:d_chart/commons/config_render.dart';
import 'package:d_chart/commons/data_model.dart';
import 'package:d_chart/ordinal/pie.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/grades.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/timetable.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:engelsburg_planer/src/view/pages/grade/grade_extended.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/settings_subject_page.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExtendedSubjectPage extends CompactStatefulWidget {
  const ExtendedSubjectPage({super.key, required this.subjectDoc});

  final Document<Subject> subjectDoc;

  @override
  State<ExtendedSubjectPage> createState() => _ExtendedSubjectPageState();
}

class _ExtendedSubjectPageState extends State<ExtendedSubjectPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_ExtendedSubjectListTileState> subjectListTileKey = GlobalKey();

  late final AnimationController controller;
  late final Animation<double> animation;

  bool editingGradeTypes = false;

  List<GradeType>? gradeTypes;

  void updateSubject() {
    bool flush = false;
    var subject = widget.subjectDoc.data!;

    if (!listEquals(gradeTypes, subject.getGradeTypes(context))) {
      subject.gradeTypes = gradeTypes!;
      flush = true;
    }

    if (flush) widget.subjectDoc.setDelayed(subject);
  }

  void _changeOtherSliders(GradeType? type) {
    var delta = 1 - gradeTypes!.fold(0, (pre, e) => pre + e.share);

    for (var i = gradeTypes!.length - 1; i >= 0 && delta != 0; i--) {
      var toChange = gradeTypes![i];
      if (type == toChange) continue;

      var diff = toChange.share + delta;
      if (diff > 1) {
        delta = diff - 1;
        toChange.share = 1;
      } else if (diff < 0) {
        delta = diff - 2 * toChange.share;
        toChange.share = 0;
      } else {
        delta = 0;
        toChange.share = diff;
      }
    }

    //Update subject when finished
    updateSubject();
  }

  Color _getDonutColor(int index) {
    switch (index) {
      case 0:
        return Colors.blueAccent;
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.greenAccent;
      default:
        return Colors.orangeAccent;
    }
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    animation = CurvedAnimation(parent: controller, curve: Curves.decelerate);
  }

  @override
  Widget build(BuildContext context) {
    var heroTag = StringUtils.randomAlphaNumeric(10);

    return Scaffold(
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
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        actions: [
          const Flex(direction: Axis.horizontal),
          IconButton(
            icon: const Icon(Icons.delete),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () => context.dialog(const ConfirmDeleteSubjectDialog()).then((value) {
              if (!(value ?? false)) return;

              widget.subjectDoc.delete();
              Timetable.entries().defaultStorage(context).documents().then((items) {
                for (var entry in items) {
                  entry.load().then((data) {
                    if (data.subject == widget.subjectDoc) {
                      data.subject = null;
                      if (data.isEmpty) {
                        entry.delete();
                      } else {
                        entry.set(data);
                      }
                    }
                  });
                }
              });
              Grades.entries().defaultStorage(context).documents().then((items) {
                for (var grade in items) {
                  grade.load().then((data) {
                    if (data.subject == widget.subjectDoc) grade.delete();
                  });
                }
              });
              globalContext().pop();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: StringUtils.randomAlphaNumeric(10),
        child: const Icon(Icons.add_circle_outlined),
        onPressed: () => context.pushPage(ExtendedGradePage(subject: widget.subjectDoc)),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamConsumer<Subject>(
          doc: widget.subjectDoc,
          itemBuilder: (context, doc, subject) {
            gradeTypes ??= subject.getGradeTypes(context);

            return ListView(
              children: [
                ExtendedSubjectListTile(
                  key: subjectListTileKey,
                  subject: widget.subjectDoc,
                  heroTag: heroTag,
                ),
                AspectRatio(
                  aspectRatio: 2,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: SizedBox(
                          height: 250,
                          child: Stack(
                            children: [
                              DChartPieO(
                                animate: false,
                                 customLabel:  (_, __) => "",
                                 configRenderPie: const ConfigRenderPie(
                                   arcWidth: 20,
                                   strokeWidthPx: 0,
                                 ),
                                data: gradeTypes!.mapIndex((type, index) {
                                  return OrdinalData(
                                    domain: type.name,
                                    measure: type.share,
                                    color: _getDonutColor(index),
                                  );
                                }).toList(),
                              ),
                              Center(
                                child: IconButton(
                                  icon:
                                      Icon(editingGradeTypes ? Icons.done : Icons.edit, size: 30),
                                  onPressed: () => setState(() {
                                    editingGradeTypes = !editingGradeTypes;
                                    editingGradeTypes
                                        ? controller.forward()
                                        : controller.reverse();
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Flexible(
                        flex: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: gradeTypes!.mapIndex((type, index) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(backgroundColor: _getDonutColor(index), radius: 5),
                                const SizedBox(width: 5),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    "${(type.share * 100).roundToPlaces(1)}%",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "- ${type.name}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) => SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...gradeTypes!.mapIndex((type, index) {
                          var nameController = TextEditingController(text: type.name);
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: TextField(
                                        controller: nameController,
                                        maxLength: 30,
                                        maxLines: 1,
                                        style: const TextStyle(fontSize: 18),
                                        onChanged: (value) {
                                          type.name = value;
                                        },
                                      ),
                                    ),
                                  ),
                                  if (gradeTypes!.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () => setState(() {
                                        gradeTypes!.removeAt(index);
                                        _changeOtherSliders(null);
                                      }),
                                    ),
                                ],
                              ),
                              Slider(
                                activeColor: _getDonutColor(index),
                                value: type.share,
                                divisions: 20,
                                label: "${(type.share * 100).roundToPlaces(1)}%",
                                max: 1,
                                onChanged: (value) {
                                  if (gradeTypes!.length == 1) return;
                                  setState(() {
                                    type.share = value;
                                    _changeOtherSliders(type);
                                  });
                                },
                              ),
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ChoiceChip(
                                      label: const Text("2/3"),
                                      selectedColor: _getDonutColor(index),
                                      padding: EdgeInsets.zero,
                                      selected: type.share.roundToPlaces(13) ==
                                          (2 / 3).roundToPlaces(13),
                                      onSelected: (value) => setState(() {
                                        if (!value) return;
                                        if (gradeTypes!.length == 1) return;
                                        type.share = 2 / 3;
                                        _changeOtherSliders(type);
                                      }),
                                    ),
                                    ChoiceChip(
                                      label: const Text("1/3"),
                                      selectedColor: _getDonutColor(index),
                                      padding: EdgeInsets.zero,
                                      selected: type.share.roundToPlaces(13) ==
                                          (1 / 3).roundToPlaces(13),
                                      onSelected: (value) => setState(() {
                                        if (!value) return;
                                        if (gradeTypes!.length == 1) return;
                                        type.share = 1 / 3;
                                        _changeOtherSliders(type);
                                      }),
                                    ),
                                    ChoiceChip(
                                      label: const Text("1/6"),
                                      selectedColor: _getDonutColor(index),
                                      padding: EdgeInsets.zero,
                                      selected: type.share.roundToPlaces(13) ==
                                          (1 / 6).roundToPlaces(13),
                                      onSelected: (value) => setState(() {
                                        if (!value) return;
                                        if (gradeTypes!.length == 1) return;
                                        type.share = 1 / 6;
                                        _changeOtherSliders(type);
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                        if (gradeTypes!.length < 4)
                          ElevatedButton(
                            child: Text(context.l10n.addTypeOfGrade),
                            onPressed: () => setState(() {
                              var type = GradeType(
                                name: context.l10n.otherParticipation,
                                share: 1 / 6,
                              );
                              gradeTypes!.add(type);
                              _changeOtherSliders(type);
                            }),
                          ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<List<Document<Grade>>>(
                  stream: Grades.entries().defaultStorage(context).stream().map((event) {
                    return event
                        .where((grades) => grades.data!.subject == widget.subjectDoc)
                        .toList();
                  }),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    var grades = snapshot.data!;
                    if (grades.isEmpty) return Container();

                    var gradeTypes = subject.getGradeTypes(context);
                    List<List<Document<Grade>>> sortedGrades =
                        List.generate(gradeTypes.length, (_) => []);
                    for (var element in grades) {
                      var index = element.data!.gradeType;
                      if (index > gradeTypes.length - 1) continue;

                      sortedGrades[index] = sortedGrades[index]..add(element);
                    }

                    return StreamConsumer<Grades>(
                      doc: Grades.ref().defaultStorage(context),
                      itemBuilder: (context, doc, config) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: sortedGrades.mapIndex((loadedGrades, index) {
                          if (loadedGrades.isEmpty) return Container();
                          var gradeTypeName = gradeTypes[index].name;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 3,
                                    child: Text(
                                      gradeTypeName,
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Flexible(
                                    flex: 1,
                                    child: Text(
                                      (loadedGrades.fold<int>(0, (p, e) => p + e.data!.value(config.usePoints)) /
                                              loadedGrades.length)
                                          .roundToPlaces(2)
                                          .toString(),
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...loadedGrades.mapIndex((doc, i) {
                                var grade = doc.data!;

                                return ListTile(
                                  horizontalTitleGap: 0,
                                  leading: SizedBox(
                                    height: double.infinity,
                                    child: CircleAvatar(
                                      backgroundColor: _getDonutColor(index),
                                      radius: 10,
                                    ),
                                  ),
                                  title: Text(grade.name ?? "${i + 1}. $gradeTypeName"),
                                  trailing: Text(
                                    grade.value(config.usePoints).toString(),
                                    textScaler: const TextScaler.linear(1.5),
                                  ),
                                  subtitle: Text(grade.created.formatEEEEddMM(context)),
                                  onTap: () {
                                    context.pushPage(
                                      ExtendedGradePage(
                                        grade: grades.where((e) => e == doc).first,
                                        heroTag: heroTag,
                                      ),
                                    );
                                  },
                                );
                              }),
                              const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ExtendedSubjectListTile extends StatefulWidget {
  const ExtendedSubjectListTile({super.key, required this.subject, this.heroTag});

  final Document<Subject> subject;
  final String? heroTag;

  @override
  State<ExtendedSubjectListTile> createState() => _ExtendedSubjectListTileState();
}

class _ExtendedSubjectListTileState extends State<ExtendedSubjectListTile>
    with AutomaticKeepAliveClientMixin {
  bool _editName = false;
  TextEditingController? _customNameController;

  Color? color;
  String? name;

  void updateSubject() {
    bool flush = false;
    var subject = widget.subject.data!;

    if (color != null && color! != subject.parsedColor) {
      subject.color = color!.toHex();
      flush = true;
    }
    if (name != null && name != subject.parsedName(context)) {
      subject.customName = name;
      flush = true;
    }

    if (flush) widget.subject.setDelayed(subject);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var subject = widget.subject.data;
    _customNameController ??= TextEditingController(text: subject?.parsedName(context) ?? context.l10n.noSubjectSelected);

    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: OptionalHero(
          tag: widget.heroTag,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: color ?? context.subjectColor(subject),
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                Color? color = await context.dialog(
                  SelectColorDialog(color: context.subjectColor(subject)),
                );
                if (color == null) return;

                setState(() => this.color = color);
                updateSubject();
              },
            ),
          ),
        ),
      ),
      title: Align(
        alignment: Alignment.centerLeft,
        child: Builder(builder: (context) {
          if (_editName) {
            return SizedBox(
              width: MediaQuery.of(context).size.width - 100,
              height: 60,
              child: TextField(
                enabled: _editName,
                controller: _customNameController,
                maxLength: 30,
                style: const TextStyle(fontSize: 18),
                onChanged: (value) => name = value,
              ),
            );
          }

          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _customNameController!.text,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w300,
              ),
            ),
          );
        }),
      ),
      trailing: SizedBox.square(
        dimension: 25,
        child: IconButton(
          icon: Icon(_editName ? Icons.done : Icons.edit),
          onPressed: () {
            setState(() => _editName = !_editName);
            if (!_editName) updateSubject();
          },
        ),
      ),
      subtitle: subject == null ? null : Text([
        if (subject.customName != null) BaseSubject.get(subject).l10n(context)!,
        BaseSubject.get(subject).l10nGroup(context),
      ].join(" - ")),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
