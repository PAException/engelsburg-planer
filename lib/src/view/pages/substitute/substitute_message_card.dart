/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */


import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';

class SubstituteMessageCard extends StatefulWidget {
  const SubstituteMessageCard({super.key, required this.substituteMessage});

  final SubstituteMessage substituteMessage;

  @override
  SubstituteMessageCardState createState() => SubstituteMessageCardState();
}

class SubstituteMessageCardState extends State<SubstituteMessageCard> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  widget.substituteMessage.date!.formatEEEEddMM(context),
                  textScaleFactor: 2,
                ),
              ),
              const Divider(height: 10, thickness: 5),
              const SizedBox(height: 10),
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  if (widget.substituteMessage.absenceTeachers != null)
                    TableRow(
                      children: [
                        Text(context.l10n.absenceTeachers),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.absenceTeachers!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.absenceClasses != null)
                    TableRow(
                      children: [
                        Text(context.l10n.absenceClasses),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.absenceClasses!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.affectedClasses != null)
                    TableRow(
                      children: [
                        Text(context.l10n.affectedClasses),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.affectedClasses!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.affectedRooms != null)
                    TableRow(
                      children: [
                        Text(context.l10n.affectedRooms),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.affectedRooms!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.blockedRooms != null)
                    TableRow(
                      children: [
                        Text(context.l10n.blockedRooms),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.blockedRooms!),
                        ),
                      ],
                    ),
                  if (widget.substituteMessage.messages != null)
                    TableRow(
                      children: [
                        Text(context.l10n.substituteMessages),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(widget.substituteMessage.messages!),
                        ),
                      ],
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
