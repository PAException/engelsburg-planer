/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:d_chart/d_chart.dart';
import 'package:engelsburg_planer/src/models/db/grades.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/util.dart';
import 'package:engelsburg_planer/src/view/pages/home/grade/extended_grade.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_settings_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExtendedSubjectPage extends CompactStatefulWidget {
  const ExtendedSubjectPage({Key? key, required this.subject}) : super(key: key);

  final Document<Subject> subject;

  @override
  State<ExtendedSubjectPage> createState() => _ExtendedSubjectPageState();
}

class _ExtendedSubjectPageState extends State<ExtendedSubjectPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<_ExtendedSubjectListTileState> listTileKey = GlobalKey();

  late final AnimationController controller;
  late final Animation<double> animation;

  Subject? subject;

  bool editingGradeTypes = false;
  List<GradeType>? gradeTypes;

  Future<bool> savePossibleChanges() {
    if (subject == null) return SynchronousFuture(true);
    bool markForFlush = false;

    var name = listTileKey.currentState!.name;
    if (name != null && name != subject!.parsedName(context)) {
      subject!.customName = name;
      markForFlush = true;
    }

    var color = listTileKey.currentState!.color;
    if (color != null && color != subject!.parsedColor) {
      subject!.color = color.toHex();
      markForFlush = true;
    }
    if (!listEquals(gradeTypes, subject!.gradeTypes)) {
      subject!.gradeTypes = gradeTypes!;
      markForFlush = true;
    }

    if (markForFlush) widget.subject.flush();
    return SynchronousFuture(true);
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

    return WillPopScope(
      onWillPop: savePossibleChanges,
      child: Scaffold(
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
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => context.dialog(const ConfirmDeleteSubjectDialog()).then((value) {
                if (!value) return;

                widget.subject.delete();
                Grades.get().entries.items.then((items) {
                  for (var grade in items) {
                    grade.load().then((data) {
                      if (data.subject == widget.subject) grade.delete();
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
          onPressed: () => context.pushPage(ExtendedGradePage(subject: widget.subject)),
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StreamBuilder<Subject?>(
            initialData: widget.subject.data,
            stream: widget.subject.snapshots(),
            builder: (context, snapshot) {
              subject = snapshot.data;
              if (subject == null) return const Placeholder();

              gradeTypes ??= subject!.getGradeTypes(context);

              return ListView(
                children: [
                  ExtendedSubjectListTile(key: listTileKey, subject: subject!, heroTag: heroTag),
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
                                DChartPie(
                                  fillColor: (pieData, index) => _getDonutColor(index!),
                                  donutWidth: 20,
                                  showLabelLine: false,
                                  pieLabel: (pieData, index) => "",
                                  data: gradeTypes!
                                      .mapIndex((type, index) => {
                                            "domain": type.name,
                                            "measure": type.share,
                                          })
                                      .toList(),
                                  animate: false,
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
                    stream: Grades.get().entries.snapshots().map((event) {
                      return event
                          .where((grades) => grades.data!.subject == widget.subject)
                          .toList();
                    }),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var grades = snapshot.data!;
                      if (grades.isEmpty) return Container();

                      List<List<Grade>> sortedGrades =
                          List.generate(subject!.gradeTypes.length, (_) => []);
                      for (var element in grades) {
                        var index = element.data!.gradeType;
                        if (index > subject!.gradeTypes.length - 1) continue;

                        sortedGrades[index] = sortedGrades[index]..add(element.data!);
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: sortedGrades.mapIndex((loadedGrades, index) {
                          if (loadedGrades.isEmpty) return Container();
                          var gradeTypeName = subject!.gradeTypes[index].name;

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
                                      (loadedGrades.fold<int>(0, (p, e) => p + e.value()) /
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
                              ...loadedGrades.mapIndex((grade, i) {
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
                                    grade.points.toString(),
                                    textScaleFactor: 1.5,
                                  ),
                                  subtitle: Text(grade.created.formatEEEEddMM(context)),
                                  onTap: () {
                                    context.pushPage(
                                      ExtendedGradePage(
                                        grade: grades.where((e) => e.data == grade).first,
                                        pushedFromSubjectPage: true,
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
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ExtendedSubjectListTile extends StatefulWidget {
  const ExtendedSubjectListTile({Key? key, required this.subject, this.heroTag}) : super(key: key);

  final Subject subject;
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var subject = widget.subject;
    _customNameController ??= TextEditingController(text: subject.parsedName(context));

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
          },
        ),
      ),
      subtitle: Text([
        if (subject.customName != null) BaseSubject.get(subject).l10n(context)!,
        BaseSubject.get(subject).l10nGroup(context),
      ].join(" - ")),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
