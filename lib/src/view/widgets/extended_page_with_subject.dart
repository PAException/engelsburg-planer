/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:async';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/subjects.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/base/document.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/settings/subject/subject_select_page.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';

class ExtendedPageWithSubject extends StatefulWidget {
  const ExtendedPageWithSubject({
    super.key,
    required this.onEdit,
    required this.children,
    this.onDelete,
    this.editing = false,
    this.subject,
    this.heroTag,
    this.subtitle,
  });

  final Document<Subject>? subject;
  final String? heroTag;
  final VoidCallback? onDelete;
  final FutureOr<bool> Function(bool edit, Document<Subject>? subject) onEdit;
  final bool editing;
  final Text? subtitle;
  final List<Widget> Function(bool edit, Subject? subject) children;

  @override
  State<ExtendedPageWithSubject> createState() => _ExtendedPageWithSubjectState();
}

class _ExtendedPageWithSubjectState extends State<ExtendedPageWithSubject> {
  late bool _editing;
  Document<Subject>? currentSubject;

  @override
  void initState() {
    super.initState();
    _editing = widget.editing;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
          if (_editing && widget.onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => widget.onDelete!.call(),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(_editing ? Icons.done : Icons.edit_outlined),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () {
                Future.value(widget.onEdit.call(!_editing, currentSubject ?? widget.subject))
                    .then((allow) {
                  if (allow) setState(() => _editing = !_editing);
                });
              },
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: NullableStreamConsumer<Subject>(
            doc: (currentSubject ?? widget.subject)?.defaultStorage(context),
            itemBuilder: (context, doc, subject) {
              return ListView(
                children: [
                  ListTile(
                    leading: OptionalHero(
                      tag: widget.heroTag,
                      child: SizedBox.square(
                        dimension: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: context.subjectColor(subject),
                          ),
                        ),
                      ),
                    ),
                    title: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subject?.parsedName(context) ?? context.l10n.pickSubject,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    subtitle: widget.subtitle,
                    onTap: _editing
                        ? () async {
                            Document<Subject>? res =
                                await context.pushPage(const SelectSubjectPage());
                            if (res == null) return;

                            currentSubject = res;
                            setState(() {});
                          }
                        : null,
                  ),
                  ...widget.children.call(_editing, subject),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
