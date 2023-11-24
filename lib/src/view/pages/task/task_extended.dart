/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_select_page.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:engelsburg_planer/src/view/widgets/util/wrap_if.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/tasks.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';

class ExtendedTask extends CompactStatefulWidget {
  const ExtendedTask({super.key, this.task, this.editing});

  final Document<Task>? task;
  final bool? editing;

  @override
  State<ExtendedTask> createState() => _ExtendedTaskState();
}

class _ExtendedTaskState extends State<ExtendedTask> {
  Document<Task>? taskDoc;

  late TextEditingController titleController;
  Document<Subject>? subject;
  DateTime? date;
  DateTime? due;
  late TextEditingController contentController;

  bool _editing = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) _editing = widget.editing!;
    taskDoc = widget.task;

    titleController = TextEditingController(text: taskDoc?.data?.title);
    subject = widget.task?.data?.subject?.defaultStorage(context);
    date = widget.task?.data?.created ?? DateTime.now();
    due = widget.task?.data?.due;
    contentController = TextEditingController(text: taskDoc?.data?.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton(
            icon: Icon(
              Icons.clear,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: context.pop,
          ),
        ),
        actions: [
          const Flex(direction: Axis.horizontal),
          if (_editing && taskDoc != null)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                taskDoc!.delete();
                context.pop();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(_editing ? Icons.done : Icons.edit_outlined),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                if (!_editing) {
                  setState(() => _editing = !_editing);
                  return;
                }

                if (titleController.text.isEmpty) return;
                if (widget.task != null) {
                  //Edit
                  var task = taskDoc!.data!;
                  bool markForFlush = false;

                  var title = titleController.text;
                  if (title != task.title) {
                    task.title = title;
                    markForFlush = true;
                  }
                  if (subject != null && subject != task.subject) {
                    task.subject = subject;
                    markForFlush = true;
                  }
                  if (date != null && date != task.created) {
                    task.created = date!;
                    markForFlush = true;
                  }
                  if (due != task.due) {
                    task.due = due!;
                    markForFlush = true;
                  }
                  var content = contentController.text;
                  if (content != task.content) {
                    task.content = content;
                    markForFlush = true;
                  }

                  if (markForFlush) taskDoc!.setDelayed(task);
                } else {
                  //Only add
                  Tasks.entries().defaultStorage(context).addDocument(Task(
                        title: titleController.text,
                        subject: subject,
                        created: date!,
                        due: due,
                        content: contentController.text,
                        done: false,
                      ));
                  context.pop();
                }

                setState(() => _editing = !_editing);
              },
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(8),
          child: ListView(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 8),
                      child: _editing
                          ? TextField(
                              controller: titleController,
                              maxLength: 30,
                              style: const TextStyle(fontSize: 20),
                              decoration: InputDecoration(hintText: context.l10n.title),
                            )
                          : Text(
                              titleController.text,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: SizedBox.square(
                  dimension: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: context.subjectColor(subject?.data),
                    ),
                  ),
                ),
                title: WrapIf(
                  condition: _editing,
                  wrap: (child, context) {
                    return ElevatedButton(
                      onPressed: () async {
                        Document<Subject>? res = await context.pushPage(const SelectSubjectPage());
                        if (res == null) return;

                        subject = res;
                        setState(() {});
                      },
                      child: child,
                    );
                  },
                  child: Text(
                    subject?.data?.parsedName(context) ?? context.l10n.noSubjectSelected,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.today),
                title: WrapIf(
                  condition: _editing,
                  child: Text(date!.formatEEEEddMM(context)).fontSize(18),
                  wrap: (child, context) {
                    return ElevatedButton(
                      onPressed: () async {
                        var date = await context.dialog(DatePickerDialog(
                          firstDate: DateTime.fromMillisecondsSinceEpoch(0),
                          initialDate: DateTime.now(),
                          lastDate: DateTime.now(),
                        ));
                        if (date == null) return;

                        setState(() => this.date = date);
                      },
                      child: child,
                    );
                  },
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.date_range),
                title: WrapIf(
                  condition: _editing,
                  child: Text(due?.formatEEEEddMM(context) ?? context.l10n.due).fontSize(18),
                  wrap: (child, context) {
                    return ElevatedButton(
                      onPressed: () async {
                        var due = await context.dialog(DatePickerDialog(
                          firstDate: date!,
                          initialDate: date!,
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        ));

                        setState(() => this.due = due);
                      },
                      child: child,
                    );
                  },
                ),
              ),
              _editing
                  ? Padding(
                      padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
                      child: TextField(
                        controller: contentController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.all(8),
                          hintText: context.l10n.description,
                        ),
                        maxLines: 10,
                        minLines: 5,
                      ),
                    )
                  : contentController.text.isNotEmpty
                      ? ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(
                            contentController.text.trim(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : Container(),
              if (!_editing && taskDoc != null && !taskDoc!.data!.done)
                ElevatedButton(
                  onPressed: () {
                    var task = taskDoc!.data!;
                    task.done = !task.done;
                    taskDoc!.setDelayed(task);
                    context.pop();
                  },
                  child: Text(context.l10n.done),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
