/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart';

import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/view/widgets/util/api_future_builder.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_card.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';

class SubstituteTab extends StatefulWidget {
  const SubstituteTab({super.key});

  @override
  State<SubstituteTab> createState() => _SubstituteTabState();
}

class _SubstituteTabState extends State<SubstituteTab> {
  /// Merges substitutes that only differ by lesson and the lessons are
  /// consecutively. Returns substitutes referring to an int that represents
  /// the last lesson, if the substitutes have been merged.
  Map<Substitute, int?> mergeSubstitutes(List<Substitute> substitutes) {
    Map<Substitute, int?> merged = {};
    List<Substitute> ignore = [];
    for (Substitute substitute in substitutes) {
      if (ignore.contains(substitute)) continue;

      int? lesson;
      Substitute latest = substitute;
      while (lesson == null) {
        var next = substitutes.firstNullableWhere((s) => latest.isPreceding(s));

        if (next != null) {
          latest = next;
          ignore.add(next);
        } else {
          lesson = latest.lesson!;
        }
      }

      merged[substitute] = lesson;
    }

    return merged.map((key, value) {
      if (key.lesson == value) value = null;

      return MapEntry(key, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamConsumer<SubstituteSettings>(
      doc: SubstituteSettings.ref().defaultStorage(context),
      itemBuilder: (context, doc, substituteSettings) {
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ApiFutureBuilder<Substitutes>(
            request: getSubstitutes(
              substituteSettings.password!,
              classes: substituteSettings.byClasses
                  ? substituteSettings.classes
                  : [],
              teacher: substituteSettings.byTeacher
                  ? substituteSettings.teacher
                  : [],
            ).build(),
            parser: (json) => Substitutes.fromJson(json),
            dataBuilder: (substitutesResponse, refresh, context) {
              var merged =
                  mergeSubstitutes(substitutesResponse.substitutes..sort());
              var substitutes = merged.keys.toList();

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    if (index == substitutes.length) {
                      return SubstituteState(
                        timestamp: substitutesResponse.timestamp,
                      );
                    }

                    bool addText = index == 0 ||
                        substitutes[index - 1].date != substitutes[index].date;

                    return WrapIf(
                      condition: addText,
                      wrap: (child, context) => Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                substitutes[index]
                                    .date!
                                    .formatEEEEddMM(context),
                                textScaler: const TextScaler.linear(2),
                                textAlign: TextAlign.start,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          child,
                        ],
                      ),
                      child: SubstituteCard(
                        substitute: substitutes[index],
                        endLesson: merged[substitutes[index]],
                      ),
                    );
                  },
                  itemCount: substitutes.length + 1,
                  padding: const EdgeInsets.all(10),
                  separatorBuilder: (_, __) => Container(height: 10),
                ),
              );
            },
            errorBuilder: (error, context) {
              if (error.isForbidden) {
                substituteSettings.password = null;
                NotificationSettings.ref()
                    .defaultStorage(context)
                    .load()
                    .then((value) => value.updateSubstituteSettings());
                doc.setDelayed(substituteSettings);
              }

              return ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: Text(context.l10n.noSubstitutes),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class SubstituteState extends StatelessWidget {
  final int timestamp;

  const SubstituteState({super.key, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    return Center(
        child: Text(
      "${context.l10n.stateOf} ${date.format(context, "dd.MM., HH:mm")}",
      textScaler: const TextScaler.linear(1.2),
    ));
  }
}
