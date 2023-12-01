/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_extended.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SubstituteCard extends StatelessWidget {
  const SubstituteCard({super.key, required this.substitute, this.endLesson});

  final Substitute substitute;
  final int? endLesson;

  @override
  Widget build(BuildContext context) {
    final heroTag = StringUtils.randomAlphaNumeric(16);

    var lesson = "${substitute.lesson}${endLesson != null ? "-$endLesson" : ""}";

    try {
      return Hero(
        tag: heroTag,
        flightShuttleBuilder: (_, __, ___, ____, toHeroContext) =>
            Material(
              child: OverflowBox(child: toHeroContext.widget),
            ), //https://github.com/flutter/flutter/issues/34119
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: color(substitute.type),
            child: ListTile(
              minVerticalPadding: 8,
              onTap: () =>
                  context.pushPage(
                    ExtendedSubstitute(
                      substitute: substitute,
                      endLesson: endLesson,
                      heroTag: heroTag,
                    ),
                  ),
              leading: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 40,
                  maxWidth: 60,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lesson,
                      textScaler: const TextScaler.linear(1.8),
                    ),
                  ],
                ),
              ),
              title: Text(
                substitute.type.name(context),
                textScaler: const TextScaler.linear(1.2),
              ),
              subtitle: SummarizedSubstituteText(substitute: substitute),
            ),
          ),
        ),
      );
    } on AssertionError catch (_) {
      return Container();
    }
  }

  static Color color(SubstituteType type) {
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
}

class SummarizedSubstituteText extends StatelessWidget {
  const SummarizedSubstituteText({super.key, required this.substitute});

  final Substitute substitute;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        RichText(
          text: TextSpan(
            text: substitute.className,
            style: DefaultTextStyle.of(context).style.copyWith(
                color: DefaultTextStyle.of(context)
                    .style
                    .color!
                    .withOpacity(0.80)),
            children: [
              TextSpan(text: substitute.className == null ? '' : ' – '),
              TextSpan(text: substitute.subject),
              const TextSpan(text: ' ('),
              TextSpan(
                  text: substitute.substituteTeacher == null ||
                          substitute.substituteTeacher == '+'
                      ? ''
                      : substitute.substituteTeacher),
              TextSpan(
                  text: substitute.substituteTeacher != null &&
                          substitute.substituteTeacher != '+' &&
                          substitute.teacher == null
                      ? ')'
                      : ''),
              TextSpan(
                  text: substitute.substituteTeacher != null &&
                          substitute.substituteTeacher != '+' &&
                          substitute.teacher != null &&
                          substitute.substituteTeacher != substitute.teacher
                      ? ' ${context.l10n.insteadOf} '
                      : ''),
              TextSpan(
                  text: substitute.teacher == substitute.substituteTeacher
                      ? ''
                      : substitute.teacher,
                  style:
                      const TextStyle(decoration: TextDecoration.lineThrough)),
              TextSpan(text: substitute.teacher != null ? ')' : ''),
              TextSpan(
                  text:
                      substitute.room == null ? '' : ' in ${substitute.room!}'),
              TextSpan(
                  text: substitute.text == null || substitute.text!.isEmpty
                      ? ''
                      : ' – ${substitute.text}'),
              TextSpan(
                  text: substitute.substituteOf == null
                      ? ''
                      : ' – ${substitute.substituteOf}')
            ],
          ),
        ),
      ],
    );
  }
}
