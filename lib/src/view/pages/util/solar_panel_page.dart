/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/solar_panel.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/api_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

class SolarPanelPage extends StatelessWidget {
  const SolarPanelPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ApiFutureBuilder<SolarPanelModel>(
      request: getSolarSystem().build(),
      parser: SolarPanelModel.fromJson,
      dataBuilder: (system, refresh, context) {
        final boxes = [
          SolarPanelInfoBox(
            icon: Icons.calendar_today,
            title: context.l10n.date,
            value: system.date!,
          ),
          SolarPanelInfoBox(
            icon: Icons.lightbulb_outline,
            title: context.l10n.energy,
            value: system.energy!,
          ),
          SolarPanelInfoBox(
            icon: Icons.landscape,
            title: context.l10n.avoidedCO2,
            value: system.co2Avoidance!,
          ),
          SolarPanelInfoBox(
            icon: Icons.monetization_on,
            title: context.l10n.renumeration,
            value: system.payment!,
          ),
        ];

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Card(
                margin: EdgeInsets.zero,
                child: LayoutBuilder(builder: (context, constraints) {
                  //If wide enough display icons in a row
                  if (constraints.maxWidth > 400) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: boxes,
                      ),
                    );
                  }

                  //Otherwise in a gridview like a square
                  return GridView.count(
                    padding: const EdgeInsets.all(16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                    children: boxes,
                  );
                }),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: HtmlWidget(
                  system.text.toString(),
                  textStyle: const TextStyle(height: 1.5, fontSize: 18.0),
                ),
              )
            ],
          ),
        );
      },
      errorBuilder: (_, context) => Center(
        child: Text(context.l10n.solarPanelPageNotFoundError),
      ),
    );
  }
}

class SolarPanelInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SolarPanelInfoBox({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 56),
        Text(title),
        const Padding(padding: EdgeInsets.only(top: 8.0)),
        Text(value)
      ],
    );
  }
}
