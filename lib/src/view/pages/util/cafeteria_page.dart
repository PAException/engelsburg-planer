/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/cafeteria.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../widgets/util/api_future_builder.dart';

class CafeteriaPage extends StatelessWidget {
  const CafeteriaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder<Cafeteria>(
      request: getCafeteria().build(),
      parser: Cafeteria.fromJson,
      dataBuilder: (cafeteria, refresh, _) => RefreshIndicator(
        onRefresh: refresh,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: HtmlWidget(cafeteria.content!),
          ),
        ),
      ),
      errorBuilder: (_, context) => Center(
        child: Text(context.l10n.cafeteriaPageNotFoundError),
      ),
    );
  }
}
