/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/teacher.dart';
import 'package:engelsburg_planer/src/backend/database/cache/session_persistent_data.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';

class TeacherListTile extends StatelessWidget {
  const TeacherListTile.edit({
    super.key,
    required this.editing,
    required this.controller,
  });

  TeacherListTile(String? abbreviation, {super.key})
      : editing = false,
        controller = TextEditingController(text: abbreviation ?? "");

  final bool editing;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    var controller = this.controller ?? TextEditingController(text: "");
    if (controller.text.isBlank && !editing) return Container();

    Widget? title, subtitle, trailing;
    if (editing) {
      title = TextField(
        controller: controller,
        maxLength: 4,
        style: const TextStyle(fontSize: 20),
        onChanged: (value) {
          controller.text = value.toUpperCase();
        },
      );

      subtitle = null;

      trailing = Tooltip(
          message: context.l10n.useTeacherAbbreviation,
          triggerMode: TooltipTriggerMode.tap,
          margin: const EdgeInsets.all(12),
          child: const Icon(Icons.help_outline));
    } else {
      title = Text(
        controller.text,
        style: const TextStyle(fontSize: 20),
      );

      var teacherName = SessionPersistentData.get<Teachers>()
          ?.teachers
          .firstNullableWhere(
              (teacher) => teacher.abbreviation == controller.text);
      if (teacherName != null) subtitle = Text(teacherName.parsedName());

      trailing = null;
    }

    return ListTile(
      leading: const Align(
        widthFactor: 1,
        alignment: Alignment.centerLeft,
        child: Icon(Icons.portrait),
      ),
      subtitle: subtitle,
      title: title,
      trailing: trailing,
    );
  }
}
