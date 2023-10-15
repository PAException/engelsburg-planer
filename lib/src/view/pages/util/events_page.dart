/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/events.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/api_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

class EventsPage extends StatelessWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder<List<Event>>(request: getEvents().build(), parser: Event.fromEvents,
      dataBuilder: (events, refresh, context) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView.separated(
          itemBuilder: (context, index) => EventListTile(events[index]),
          separatorBuilder: (context, index) =>
              const Divider(height: 2).paddingSymmetric(horizontal: 8),
          itemCount: events.length,
        ),
      ),
      errorBuilder: (_, context) => Center(
        child: Text(context.l10n.eventsNotFoundError),
      ),
    );
  }
}

class EventListTile extends StatelessWidget {
  final Event event;

  const EventListTile(this.event, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(event.title.toString()),
      subtitle: event.date == null ? null : Text(_dateFormat.format(event.date as DateTime)),
    );
  }
}
