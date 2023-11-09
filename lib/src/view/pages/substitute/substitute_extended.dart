/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_card.dart';
import 'package:engelsburg_planer/src/view/widgets/teacher_list_tile.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';

class ExtendedSubstitute extends CompactStatefulWidget {
  const ExtendedSubstitute({
    super.key,
    required this.substitute,
    required this.heroTag,
    this.endLesson,
  });

  final Substitute substitute;
  final String heroTag;
  final int? endLesson;

  @override
  ExtendedSubstituteCardState createState() => ExtendedSubstituteCardState();
}

class ExtendedSubstituteCardState extends State<ExtendedSubstitute> {
  @override
  Widget build(BuildContext context) {
    var substitute = widget.substitute;

    var start = Substitute.lessonStart(substitute.lesson!);
    var end = Substitute.lessonEnd(widget.endLesson ?? substitute.lesson!);
    String timeOfLessons = "$start - $end ${context.l10n.oclock}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Hero(
                tag: widget.heroTag,
                child: SizedBox.square(
                  dimension: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: SubstituteCard.color(substitute.type),
                    ),
                  ),
                ),
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    substitute.type.name(context),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              subtitle: Text(substitute.date!.formatEEEEddMMToNow(context)),
            ),
            SubstituteListTile(
              title: "${substitute.lesson!}${widget.endLesson != null ? " - ${widget.endLesson}" : ""}",
              subtitle: timeOfLessons,
              icon: Icons.access_time,
            ),
            SubstituteListTile(
              title: substitute.className,
              icon: Icons.class_,
            ),
            TeacherListTile(substitute.substituteTeacher),
            SubstituteListTile(
              title: substitute.subject,
              icon: Icons.school,
            ),
            SubstituteListTile(
              title: substitute.room,
              icon: Icons.room,
            ),
            SubstituteListTile(
              title: substitute.substituteOf?.isEmpty ?? true
                  ? null
                  : "${context.l10n.substituteOf} ${substitute.substituteOf!}",
              icon: Icons.event,
            ),
            SubstituteListTile(
              title: substitute.text,
              icon: Icons.description,
            ),
          ],
        ),
      ),
    );
  }
}

class SubstituteListTile extends StatelessWidget {
  const SubstituteListTile({
    super.key,
    this.title,
    required this.icon,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (title == null || title!.isEmpty) return Container();

    return ListTile(
      leading: Icon(icon),
      dense: true,
      subtitle: subtitle == null ? null : Text(subtitle!),
      title: Wrap(
        children: [
          Text(
            title!,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
