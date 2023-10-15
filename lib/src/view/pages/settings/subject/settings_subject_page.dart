/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_extended.dart';
import 'package:engelsburg_planer/src/view/widgets/util/color_grid.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';

class SubjectSettingsPage extends CompactStatefulWidget {
  const SubjectSettingsPage({Key? key}) : super(key: key);

  @override
  State<SubjectSettingsPage> createState() => _SubjectSettingsPageState();
}

class _SubjectSettingsPageState extends State<SubjectSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Document<Subject>>>(
      stream: Subjects.entries().defaultStorage(context).stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.connectionState != ConnectionState.active) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(50),
              child: Text(context.l10n.noSubjects),
            ),
          );
        }

        var data = snapshot.requireData;
        var baseSubjects = BaseSubject.getAll();

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: baseSubjects.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Divider(height: 0, thickness: 1),
          ),
          itemBuilder: (context, index) {
            var baseSubject = baseSubjects[index];

            return SubjectTile(
              subject: data.firstNullableWhere((e) => e.data!.baseSubject == baseSubject.name),
              baseSubject: baseSubject,
            );
          },
        );
      },
    );
  }
}

class SubjectTile extends StatefulWidget {
  const SubjectTile({
    Key? key,
    this.subject,
    required this.baseSubject,
  }) : super(key: key);

  final Document<Subject>? subject;
  final BaseSubject baseSubject;

  @override
  State<SubjectTile> createState() => _SubjectTileState();
}

class _SubjectTileState extends State<SubjectTile> {
  late bool enabled;
  late Color color;

  Document<Subject>? subject;

  String get subjectName => widget.subject?.data!.customName ?? baseSubjectName;

  String get baseSubjectName => widget.baseSubject.l10n(context) ?? widget.baseSubject.name;

  @override
  void initState() {
    super.initState();
    subject = widget.subject;
  }

  @override
  void didUpdateWidget(SubjectTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    subject = widget.subject;
  }

  @override
  Widget build(BuildContext context) {
    enabled = subject != null;
    color = ColorUtils.fromHex(widget.subject?.data?.color) ?? Subject.defaultColor;

    return ListTile(
      title: Text(
        subject?.data?.parsedName(context) ?? widget.baseSubject.l10n(context)!,
        textScaleFactor: 1.2,
      ),
      leading: Disabled(
        disabled: !enabled,
        child: Center(
          widthFactor: 1,
          child: SizedBox.square(
            dimension: 24,
            child: Container(
              decoration: BoxDecoration(
                color: subject?.data?.parsedColor ?? Subject.defaultColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
      trailing: enabled
          ? null
          : Center(
              widthFactor: 1,
              child: ElevatedButton(
                child: const Icon(Icons.add),
                onPressed: () {
                  //Should automatically be updated by parent widget
                  Subjects.entries().defaultStorage(context).addDocument(
                      Subject.fromBaseSubject(widget.baseSubject.name),
                  );
                },
              ),
            ),
      onTap: enabled ? () => context.pushPage(ExtendedSubjectPage(subjectDoc: subject!)) : null,
    );
  }
}

/// Dialog to select a color. A default color can be passed as an optional argument.
/// The color picked by the user will be popped.
/// If the user cancels the optional color, which was passed as an optional argument, will be popped.
/// If the user presses reset null will be popped.
class SelectColorDialog extends StatelessWidget {
  const SelectColorDialog({Key? key, this.color}) : super(key: key);

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.selectColor),
      content: SizedBox(
        width: 300,
        child: ColorGrid(
          currentColor: color,
          onColorSelected: (color) => context.pop(result: color),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(result: color),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: context.pop,
          child: Text(context.l10n.reset),
        ),
      ],
    );
  }
}

/// Dialog to confirm the deletion of a subject. Pops the corresponding bool.
class ConfirmDeleteSubjectDialog extends StatelessWidget {
  const ConfirmDeleteSubjectDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.confirmDeleteSubject),
      actions: [
        TextButton(
          onPressed: () => context.pop(result: false),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => context.pop(result: true),
          child: Text(context.l10n.ok),
        ),
      ],
    );
  }
}
