/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';

/// Select a subject from a list. Returns document of subject or null of aborted.
class SelectSubjectPage extends CompactStatelessWidget {
  const SelectSubjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.pickSubject),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(
            Icons.clear,
            color: Colors.grey,
          ),
        ),
      ),
      body: StreamBuilder<List<Document<Subject>>>(
        stream: Subjects.entries().defaultStorage(context).stream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                children: [
                  Flexible(
                    flex: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.l10n.noSubjects),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => context.navigate("/settings/subject"),
                          child: Text(context.l10n.subjects),
                        ),
                      ],
                    ),
                  ),
                  Flexible(flex: 1, child: Container()),
                ],
              ),
            );
          }

          var subjects = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            itemBuilder: (context, index) {
              var subject = subjects[index].data;

              return ListTile(
                leading: Center(
                  widthFactor: 1,
                  child: SizedBox.square(
                    dimension: 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: subject?.parsedColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  subject?.parsedName(context) ?? "Subject deleted",
                  textScaler: const TextScaler.linear(1.2),
                ),
                onTap: () => context.pop(result: subjects[index]),
              );
            },
            separatorBuilder: (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Divider(height: 0, thickness: 1),
            ),
            itemCount: subjects.length,
          );
        },
      ),
    );
  }
}
