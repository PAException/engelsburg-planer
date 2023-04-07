/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/db/tasks.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/home/task/extended_task.dart';
import 'package:engelsburg_planer/src/view/pages/home/task/task_card.dart';
import 'package:engelsburg_planer/src/view/pages/home/task/task_card_landscape.dart';
import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: StringUtils.randomAlphaNumeric(10),
        child: const Icon(Icons.add_circle),
        onPressed: () => context.pushPage(const ExtendedTask(editing: true)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<Document<Task>>>(
          stream: Tasks.get().entries.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

            var tasks = snapshot.data!;
            if (tasks.isEmpty) return Center(child: Text(context.l10n.noTasksFound));

            return LayoutBuilder(
              builder: (context, constraints) {
                if (context.isLandscape && constraints.maxWidth > 500) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      reverse: true,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(height: 8),
                      ),
                      itemBuilder: (context, index) => TaskCardLandscape(taskDoc: tasks[index]),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Divider(height: 8, thickness: 1),
                  ),
                  itemBuilder: (context, index) => TaskCard(task: tasks[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
