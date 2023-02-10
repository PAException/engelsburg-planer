/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/controller/subject_controller.dart';
import 'package:engelsburg_planer/src/models/api/subject.dart';
import 'package:engelsburg_planer/src/services/data_service.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/color_grid.dart';
import 'package:engelsburg_planer/src/view/widgets/promised.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubjectSettingsPage extends StatefulWidget {
  const SubjectSettingsPage({Key? key}) : super(key: key);

  @override
  State<SubjectSettingsPage> createState() => _SubjectSettingsPageState();
}

class _SubjectSettingsPageState extends State<SubjectSettingsPage>
    with DataStateMixin<SubjectService> {
  @override
  Widget build(BuildContext context) {
    return Promised<Subject>(
      promise: Promise<Subject>(
        fetch: () => dataService.getEditableSubjectList(),
        dbOrderBy: "baseSubject ASC",
      ),
      dataBuilder: (data, refresh, context) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          itemCount: data.length,
          separatorBuilder: (context, index) => const Divider(thickness: 2, height: 2),
          itemBuilder: (context, index) => SubjectTile(
            subject: data[index],
            baseSubject: dataService.getBaseSubject(data[index]),
          ),
        ),
      ),
      errorBuilder: (error, context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Text(AppLocalizations.of(context)!.noSubjects),
        ),
      ),
    );
  }
}

class SubjectTile extends StatefulWidget {
  const SubjectTile({
    Key? key,
    this.subject,
    required this.baseSubject,
  }) : super(key: key);

  final Subject? subject;
  final BaseSubject baseSubject;

  @override
  State<SubjectTile> createState() => _SubjectTileState();
}

class _SubjectTileState extends State<SubjectTile> with DataStateMixin<SubjectService> {
  final TextEditingController _customNameController = TextEditingController();
  bool _editingName = false;
  bool? _value;
  late Color _color;

  String get subjectName => widget.subject?.customName ?? baseSubjectName;

  String get baseSubjectName => widget.baseSubject.localization(context) ?? widget.baseSubject.name;

  @override
  void initState() {
    super.initState();
    _value = widget.subject!.subjectId != null;
    _color = ColorUtils.fromHex(widget.subject?.color) ?? Subject.defaultColor;
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.leading,
      title: _editingName
          ? FocusScope(
              onFocusChange: (value) {
                if (!value) {
                  setState(() {
                    _editingName = false;
                  });
                }
              },
              child: TextField(
                autofocus: true,
                controller: _customNameController,
                decoration: InputDecoration.collapsed(hintText: subjectName),
              ),
            )
          : InkWell(
              onTap: () {
                setState(() {
                  _customNameController.text = subjectName;
                  _editingName = true;
                });
              },
              child: Text(subjectName),
            ),
      subtitle: baseSubjectName == subjectName ? null : Text(baseSubjectName),
      secondary: Disabled(
        disabled: !_value!,
        child: InkWell(
          highlightColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          child: SizedBox.square(
            dimension: 20,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _color,
              ),
            ),
          ),
          onTap: () async {
            var color = await context.dialog(SelectColorDialog(color: _color));
            color ??= Subject.defaultColor;

            if (color != _color) {
              //TODO update
            }
          },
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      value: _value,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (bool? value) {
        if (value == null) return;
        setState(() {
          //TODO
          _value = value;
        });
      },
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
      title: Text(AppLocalizations.of(context)!.selectColor),
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
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: context.pop,
          child: Text(AppLocalizations.of(context)!.reset),
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
