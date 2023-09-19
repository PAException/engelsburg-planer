/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/api/substitutes.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';

class SubstituteCard extends StatefulWidget {
  const SubstituteCard({Key? key, required this.substitute}) : super(key: key);

  final Substitute substitute;

  @override
  State<StatefulWidget> createState() => _SubstituteCardState();
}

class _SubstituteCardState extends State<SubstituteCard> {
  @override
  Widget build(BuildContext context) {
    final heroTag = StringUtils.randomAlphaNumeric(16);

    return Hero(
      tag: heroTag,
      flightShuttleBuilder: (_, __, ___, ____, toHeroContext) =>
          Material(child: toHeroContext.widget), //https://github.com/flutter/flutter/issues/34119
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: _getTileColor(widget.substitute.type),
          child: ListTile(
            minVerticalPadding: 8,
            onTap: () => context.pushPage(
              ExtendedSubstituteCard(
                substitute: widget.substitute,
                heroTag: heroTag,
              ),
            ),
            leading: Center(
              widthFactor: 1,
              child: Text(
                widget.substitute.lesson!.toString(),
                textScaleFactor: 1.8,
              ),
            ),
            title: Text(
              widget.substitute.type.name(context),
              textScaleFactor: 1.25,
            ),
            subtitle: _buildText(),
          ),
        ),
      ),
    );
  }

  Widget _buildText() {
    return Wrap(
      children: [
        RichText(
          text: TextSpan(
            text: widget.substitute.className,
            style: DefaultTextStyle.of(context)
                .style
                .copyWith(color: DefaultTextStyle.of(context).style.color!.withOpacity(0.80)),
            children: [
              TextSpan(text: widget.substitute.className == null ? '' : ' – '),
              TextSpan(text: widget.substitute.subject),
              const TextSpan(text: ' ('),
              TextSpan(
                  text: widget.substitute.substituteTeacher == null ||
                          widget.substitute.substituteTeacher == '+'
                      ? ''
                      : widget.substitute.substituteTeacher),
              TextSpan(
                  text: widget.substitute.substituteTeacher != null &&
                          widget.substitute.substituteTeacher != '+' &&
                          widget.substitute.teacher == null
                      ? ')'
                      : ''),
              TextSpan(
                  text: widget.substitute.substituteTeacher != null &&
                          widget.substitute.substituteTeacher != '+' &&
                          widget.substitute.teacher != null &&
                          widget.substitute.substituteTeacher != widget.substitute.teacher
                      ? ' ${context.l10n.insteadOf} '
                      : ''),
              TextSpan(
                  text: widget.substitute.teacher == widget.substitute.substituteTeacher
                      ? ''
                      : widget.substitute.teacher,
                  style: const TextStyle(decoration: TextDecoration.lineThrough)),
              TextSpan(text: widget.substitute.teacher != null ? ')' : ''),
              TextSpan(
                  text: widget.substitute.room == null ? '' : ' in ${widget.substitute.room!}'),
              TextSpan(
                  text: widget.substitute.text == null || widget.substitute.text!.isEmpty
                      ? ''
                      : ' – ${widget.substitute.text}'),
              TextSpan(
                  text: widget.substitute.substituteOf == null
                      ? ''
                      : ' – ${widget.substitute.substituteOf}')
            ],
          ),
        ),
      ],
    );
  }
}

Color _getTileColor(SubstituteType type) {
  switch (type) {
    case SubstituteType.canceled:
      return Colors.red.shade700;
    case SubstituteType.independentWork:
      return Colors.purple.shade700;
    case SubstituteType.roomSubstitute:
      return Colors.lightBlueAccent.shade400;
    case SubstituteType.care:
      return Colors.green.shade600;
    default:
      return Colors.indigoAccent.shade700;
  }
}

class ExtendedSubstituteCard extends CompactStatefulWidget {
  const ExtendedSubstituteCard({
    Key? key,
    required this.substitute,
    required this.heroTag,
  }) : super(key: key);

  final Substitute substitute;
  final String heroTag;

  @override
  ExtendedSubstituteCardState createState() => ExtendedSubstituteCardState();
}

class ExtendedSubstituteCardState extends State<ExtendedSubstituteCard> {
  @override
  Widget build(BuildContext context) {
    var start = Substitute.lessonStart(widget.substitute.lesson!);
    var end = Substitute.lessonEnd(widget.substitute.lesson!);
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
          children: [
            ListTile(
              leading: Hero(
                tag: widget.heroTag,
                child: SizedBox.square(
                  dimension: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _getTileColor(widget.substitute.type),
                    ),
                  ),
                ),
              ),
              title: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.substitute.type.name(context),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
              subtitle: Text(widget.substitute.date!.formatEEEEddMMToNow(context)),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              dense: true,
              title: Text(
                widget.substitute.lesson!.toString(),
                style: const TextStyle(fontSize: 18),
              ),
              subtitle: Text(timeOfLessons),
            ),
            ListTile(
              leading: const Icon(Icons.class_),
              dense: true,
              title: Text(
                widget.substitute.className!,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.portrait),
              dense: true,
              title: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 18),
                  text: widget.substitute.substituteTeacher != null &&
                          widget.substitute.substituteTeacher != '+'
                      ? widget.substitute.substituteTeacher
                      : '',
                  children: [
                    TextSpan(
                        text: widget.substitute.substituteTeacher != null &&
                                widget.substitute.substituteTeacher != '+' &&
                                widget.substitute.teacher != null &&
                                widget.substitute.substituteTeacher != widget.substitute.teacher
                            ? ' ${context.l10n.insteadOf} '
                            : ''),
                    TextSpan(
                      text: widget.substitute.teacher ?? '',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.substitute.subject != null)
              ListTile(
                leading: const Icon(Icons.school),
                dense: true,
                title: Text(
                  widget.substitute.subject!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            if (widget.substitute.room != null)
              ListTile(
                leading: const Icon(Icons.room),
                dense: true,
                title: Text(
                  widget.substitute.room!,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            if (widget.substitute.substituteOf != null)
              ListTile(
                leading: const Icon(Icons.event),
                dense: true,
                title: Text(
                  "${context.l10n.substituteOf} ${widget.substitute.substituteOf!}",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            if (widget.substitute.text != null)
              ListTile(
                leading: const Icon(Icons.description),
                dense: true,
                title: Wrap(
                  children: [
                    Text(
                      widget.substitute.text!,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SubstituteMessageCard extends StatefulWidget {
  const SubstituteMessageCard({Key? key, required this.substituteMessage}) : super(key: key);

  final SubstituteMessage substituteMessage;

  @override
  SubstituteMessageCardState createState() => SubstituteMessageCardState();
}

class SubstituteMessageCardState extends State<SubstituteMessageCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  widget.substituteMessage.date!.formatEEEEddMM(context),
                  textScaleFactor: 2,
                ),
              ),
              const Divider(height: 10, thickness: 5),
              const SizedBox(height: 10),
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  if (widget.substituteMessage.absenceTeachers != null)
                    TableRow(
                      children: [
                        Text(context.l10n.absenceTeachers),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.absenceTeachers!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.absenceClasses != null)
                    TableRow(
                      children: [
                        Text(context.l10n.absenceClasses),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.absenceClasses!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.affectedClasses != null)
                    TableRow(
                      children: [
                        Text(context.l10n.affectedClasses),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.affectedClasses!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.affectedRooms != null)
                    TableRow(
                      children: [
                        Text(context.l10n.affectedRooms),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.affectedRooms!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.blockedRooms != null)
                    TableRow(
                      children: [
                        Text(context.l10n.blockedRooms),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.blockedRooms!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.messages != null)
                    TableRow(
                      children: [
                        Text(context.l10n.news),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.messages!),
                        ),
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
