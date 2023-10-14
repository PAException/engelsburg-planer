/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/db/tasks.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/models/storage_adapter.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_card.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_card_landscape.dart';
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
      body: Container(
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.all(8),
        child: CollectionStreamBuilder<Task>(
          collection: Tasks.entries().defaultStorage(context),
          empty: Center(child: Text(context.l10n.noTasksFound)),
          separatorBuilder: (_, __) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Divider(height: 8, thickness: 1),
          ),
          itemBuilder: (context, doc) =>
            LayoutBuilder(builder: (context, constraints) =>
              context.isLandscape && constraints.maxWidth > 500 ?
                TaskCardLandscape(taskDoc: doc) :
                TaskCard(task: doc),
          ),
        ),
      ),
    );
  }
}
