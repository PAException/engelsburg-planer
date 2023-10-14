/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/db/tasks.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';
import 'package:flutter/material.dart';

class TaskCardLandscape extends StatelessWidget {
  const TaskCardLandscape({Key? key, required this.taskDoc}) : super(key: key);

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
                      textScaleFactor: 1.6,
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
                          textScaleFactor: 1.6,
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
                  textScaleFactor: 1.6,
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
                        textScaleFactor: 1.6,
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
