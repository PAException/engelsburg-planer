/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/tasks.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';

class TaskCardLandscape extends StatelessWidget {
  const TaskCardLandscape({super.key, required this.taskDoc});

  final Document<Task> taskDoc;

  @override
  Widget build(BuildContext context) {
    var task = taskDoc.data!;

    return GestureDetector(
      onTap: () => context.pushPage(ExtendedTask(task: taskDoc)),
      child: Card(
        color: task.done ? Theme.of(context).cardColor : Theme.of(context).splashColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              Flexible(
                flex: 3,
                fit: FlexFit.tight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      textScaler: const TextScaler.linear(1.6),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (task.content != null && task.content!.isNotEmpty)
                      Text(
                        task.content!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: StreamBuilder<Subject?>(
                  stream: task.subject?.defaultStorage(context).stream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Container();
                    var subject = snapshot.data!;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundColor: subject.parsedColor,
                          radius: 12,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          subject.parsedName(context),
                          textScaler: const TextScaler.linear(1.6),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: Text(
                  context.l10n.fromDate(task.created.formatEEEEddMM(context)),
                  textScaler: const TextScaler.linear(1.6),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Flexible(
                flex: 2,
                fit: FlexFit.tight,
                child: task.due != null
                    ? Text(
                        context.l10n.toDate(task.due!.formatEEEEddMM(context)),
                        textScaler: const TextScaler.linear(1.6),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )
                    : Container(),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  icon: Icon(task.done ? Icons.clear : Icons.check),
                  onPressed: () {
                    task.done = !task.done;
                    taskDoc.setDelayed(task);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
