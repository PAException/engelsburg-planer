/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/collection_stream_builder.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/tasks.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_extended.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_card.dart';
import 'package:engelsburg_planer/src/view/pages/task/task_card_landscape.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<StatefulWidget> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {

  bool showAll = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: StringUtils.randomAlphaNumeric(10),
        icon: const Icon(Icons.add_circle_outline),
        onPressed: () => context.pushPage(const ExtendedTask(editing: true)),
        label: Text(context.l10n.addTask),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            value: showAll,
            onChanged: (value) => setState(() => showAll = value),
            title: Text(
              context.l10n.showDoneTasks,
              textScaler: const TextScaler.linear(1.2),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
          Flexible(
            child: Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.all(8),
              child: CollectionStreamBuilder<Task>(
                collection: Tasks.entries().defaultStorage(context),
                sort: (a, b) => a.data!.created.compareTo(b.data!.created),
                filter: showAll ? null : (doc) => !doc.data!.done,
                empty: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.noTasksFound,
                          textScaler: const TextScaler.linear(1.2),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ElevatedButton(
                            onPressed: () => context.pushPage(const ExtendedTask(editing: true)),
                            child: Text(context.l10n.add),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                separatorBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                ),
                itemBuilder: (context, doc) =>
                  LayoutBuilder(builder: (context, constraints) =>
                    context.isLandscape && constraints.maxWidth > 500 ?
                      TaskCardLandscape(taskDoc: doc) :
                      TaskCard(task: doc),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
