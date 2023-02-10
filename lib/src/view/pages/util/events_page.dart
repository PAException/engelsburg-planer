/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart' as requests;
import 'package:engelsburg_planer/src/models/api/events.dart';
import 'package:engelsburg_planer/src/services/synchronization_service.dart';
import 'package:engelsburg_planer/src/view/widgets/promised.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');

class EventsPage extends StatelessWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Promised<Event>(
      promise: SyncService.promise(
        request: requests.getEvents().build(),
        parse: (e) => Event.fromEvents(e),
      ),
      dataBuilder: (events, refresh, context) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView.separated(
          itemBuilder: (context, index) => EventListTile(events[index]),
          separatorBuilder: (context, index) => const Divider(height: 0),
          itemCount: events.length,
        ),
      ),
      errorBuilder: (_, context) => Center(
        child: Text(AppLocalizations.of(context)!.eventsNotFoundError),
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
