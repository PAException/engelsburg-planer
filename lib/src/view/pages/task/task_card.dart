/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/db/tasks.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';
import 'package:engelsburg_planer/src/view/widgets/util/label.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({Key? key, required this.task}) : super(key: key);

  final Document<Task> task;

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    var task = widget.task.data;
    if (task == null) return Container();

    return Card(
      child: SizedBox(
        width: 600,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.pushPage(ExtendedTask(task: widget.task));
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: AnimatedDefaultTextStyle(
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                  fontWeight: task.done ? FontWeight.normal : FontWeight.bold,
                                ),
                            duration: const Duration(milliseconds: 50),
                            child: Text(task.title),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Wrap(
                            children: [
                              NullableStreamConsumer<Subject>(
                                doc: task.subject?.defaultStorage(context),
                                itemBuilder: (context, doc, subject) {
                                  if (subject == null) return Container();

                                  return Label(
                                    subject.parsedName(context),
                                    backgroundColor: subject.parsedColor,
                                  );
                                },
                              ),
                              Label(
                                context.l10n.fromDate(task.created.format(context, "dd.MM.")),
                                backgroundColor: Theme.of(context).disabledColor,
                              ),
                              if (task.due != null)
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
                        if (task.content != null && task.content!.isNotEmpty)
                          Wrap(
                            children: [
                              AnimatedDefaultTextStyle(
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      fontWeight:
                                          task.done ? FontWeight.normal : FontWeight.bold,
                                    ),
                                duration: const Duration(milliseconds: 50),
                                child: Text(
                                  task.content!,
                                  maxLines: 3,
                                  overflow: TextOverflow.fade,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(task.done ? Icons.clear : Icons.check),
                  onPressed: () {
                    setState(() {
                      task.done = !task.done;
                      widget.task.setDelayed(task);
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
