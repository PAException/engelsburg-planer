/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/tasks.dart';
import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';
import 'package:engelsburg_planer/src/view/widgets/util/label.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});

  final Document<Task> task;

  @override
  Widget build(BuildContext context) {
    var task = this.task.data;
    if (task == null) return Container();

    return NullableStreamConsumer<Subject>(
      doc: task.subject?.defaultStorage(context),
      itemBuilder: (context, doc, subject) {
        return Card(
          color: subject?.parsedColor,
          child: SizedBox(
            width: 600,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                context.pushPage(ExtendedTask(task: this.task));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedDefaultTextStyle(
                              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                fontWeight: task.done ? FontWeight.normal : FontWeight.w600,
                              ),
                              duration: const Duration(milliseconds: 50),
                              child: Text(
                                subject?.parsedName(context) ?? task.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.due != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  children: [
                                    Label(
                                      context.l10n.toDate(task.due!.formatEEEEddMM(context)),
                                      backgroundColor: task.due!.isTomorrow
                                          ? Colors.orangeAccent
                                          : task.due!.isToday ||
                                          !task.due!.isAfter(DateTime.now())
                                          ? Colors.redAccent
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ],
                                ),
                              ),
                            if (subject != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  children: [
                                    AnimatedDefaultTextStyle(
                                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                        fontWeight:
                                        task.done ? FontWeight.normal : FontWeight.bold,
                                      ),
                                      duration: const Duration(milliseconds: 50),
                                      child: Text(
                                        task.title,
                                        maxLines: 3,
                                        textScaleFactor: 1.2,
                                        overflow: TextOverflow.fade,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(task.done ? Icons.clear : Icons.check),
                      onPressed: () {
                        task.done = !task.done;
                        this.task.setDelayed(task);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
