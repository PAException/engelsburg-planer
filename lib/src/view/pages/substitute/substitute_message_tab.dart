/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart';

import 'package:engelsburg_planer/src/backend/api/model/substitutes.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_consumer.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_message_card.dart';
import 'package:engelsburg_planer/src/view/widgets/util/api_future_builder.dart';

class SubstituteMessageTab extends StatefulWidget {
  const SubstituteMessageTab({super.key});

  @override
  State<SubstituteMessageTab> createState() => _SubstituteMessageTabState();
}

class _SubstituteMessageTabState extends State<SubstituteMessageTab> {
  @override
  Widget build(BuildContext context) {
    return StreamConsumer<SubstituteSettings>(
      doc: SubstituteSettings.ref().defaultStorage(context),
      itemBuilder: (context, doc, substituteSettings) {
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ApiFutureBuilder<List<SubstituteMessage>>(
            request:
                getSubstituteMessages(substituteSettings.password!).build(),
            parser: SubstituteMessage.fromSubstituteMessages,
            dataBuilder: (substituteMessages, refresh, context) =>
                ListView.separated(
              itemBuilder: (context, index) => SubstituteMessageCard(
                substituteMessage: substituteMessages[index],
              ),
              padding: const EdgeInsets.all(10),
              separatorBuilder: (context, index) => Container(height: 10),
              itemCount: substituteMessages.length,
            ),
            errorBuilder: (error, context) {
              if (error.isForbidden) {
                substituteSettings.password = null;
                NotificationSettings.ref()
                    .defaultStorage(context)
                    .load()
                    .then((value) => value.updateSubstituteSettings());
                doc.setDelayed(substituteSettings);
              }

              return ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: Text(context.l10n.noSubstituteMessages),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
