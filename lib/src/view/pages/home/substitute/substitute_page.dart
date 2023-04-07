/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:convert';

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:crypto/crypto.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/dto/substitute_dto.dart';
import 'package:engelsburg_planer/src/models/api/substitutes.dart';
import 'package:engelsburg_planer/src/models/db/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/models/db/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/models/storage.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/pages/home/substitute/substitute_card.dart';
import 'package:engelsburg_planer/src/view/widgets/api_future_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubstitutesPage extends StatelessWidget {
  const SubstitutesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamSelector<SubstituteSettings, bool>(
      doc: SubstituteSettings.get(),
      selector: (substituteSettings) => substituteSettings.password != null,
      builder: (context, doc, t, value) =>
          value ? const SubstitutePageContent() : const SubstituteKeyPage(),
    );
  }
}

class SubstituteKeyPage extends StatelessWidget {
  const SubstituteKeyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? substituteKeyHash;
    getSubstituteKeyHash().build().api<String>((json) {
      if (json is String) return json;
      if (json is List) return json[0];

      return json["sha1"];
    }).then((value) {
      if (value.dataPresent) substituteKeyHash = value.data;
    });

    var keyController = TextEditingController();

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32.0),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.l10n.verifyUserIsStudent,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            TextFormField(
              controller: keyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: context.l10n.substitutesPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            Container(
              height: 64.0,
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (keyController.text.isEmpty) return;
                  var substituteKey = keyController.text;

                  var digest = sha1.convert(utf8.encode(substituteKey));
                  if (substituteKeyHash == null || digest.toString() == substituteKeyHash) {
                    var doc = SubstituteSettings.get();
                    doc.load().then((value) {
                      value.password = substituteKey;
                      NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                      doc.flush();
                    });
                  } else {
                    context.showL10nSnackBar((l10n) => l10n.wrongSubstituteKeyError);
                  }
                },
                child: Text(
                  context.l10n.check,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubstitutePageContent extends StatefulWidget {
  const SubstitutePageContent({Key? key}) : super(key: key);

  @override
  State<SubstitutePageContent> createState() => _SubstitutePageContentState();
}

class _SubstitutePageContentState extends State<SubstitutePageContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  static int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: tabIndex, length: 2, vsync: this);
    _pageController = PageController(initialPage: tabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (context.isLandscape && constraints.maxWidth > 500) {
          return Row(
            children: [
              Flexible(
                child: Column(
                  children: [
                    Text(
                      context.l10n.substitutes,
                      textAlign: TextAlign.center,
                      textScaleFactor: 2,
                    ),
                    const Expanded(child: SubstituteTab()),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  children: [
                    Text(
                      context.l10n.substituteMessages,
                      textAlign: TextAlign.center,
                      textScaleFactor: 2,
                    ),
                    const Expanded(child: SubstituteMessageTab()),
                  ],
                ),
              ),
            ],
          );
        }

        return Scaffold(
          appBar: TabBar(
            indicatorColor: Theme.of(context).textTheme.bodyLarge!.color,
            labelColor: Theme.of(context).textTheme.bodyLarge!.color,
            onTap: (index) {
              tabIndex = index;
              _tabController.index = index;
              _pageController.animateToPage(index,
                  duration: kTabScrollDuration, curve: Curves.ease);
            },
            controller: _tabController,
            tabs: [
              Tab(text: context.l10n.substitutes),
              Tab(text: context.l10n.substituteMessages),
            ],
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: const [
              SubstituteTab(),
              SubstituteMessageTab(),
            ],
          ),
        );
      },
    );
  }
}

class SubstituteTab extends StatefulWidget {
  const SubstituteTab({Key? key}) : super(key: key);

  @override
  State<SubstituteTab> createState() => _SubstituteTabState();
}

class _SubstituteTabState extends State<SubstituteTab> {
  @override
  Widget build(BuildContext context) {
    var addedSubstituteDates = 0;

    return StreamConsumer<SubstituteSettings>(
      doc: SubstituteSettings.get(),
      builder: (context, doc, substituteSettings) {
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ApiFutureBuilder<List<SubstituteDTO>>(
            request: getSubstitutes(substituteSettings.password!).build(),
            parser: (json) => Substitute.fromSubstitutes(json)
                .map((e) => SubstituteDTO.fromSubstitute(e))
                .toList()
              ..sort(),
            dataBuilder: (substitutes, refresh, context) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    bool addText =
                        index != 0 && substitutes[index - 1].date == substitutes[index].date;
                    if (addText) addedSubstituteDates++;

                    return addText
                        ? SubstituteCard(substitute: substitutes[index])
                        : Column(
                            children: [
                              Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      substitutes[index].date!.formatEEEEddMM(context),
                                      textScaleFactor: 2,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  )),
                              SubstituteCard(substitute: substitutes[index])
                            ],
                          );
                  },
                  itemCount: substitutes.length + addedSubstituteDates,
                  padding: const EdgeInsets.all(10),
                  separatorBuilder: (_, __) => Container(height: 10),
                ),
              );
            },
            errorBuilder: (error, context) {
              if (error.isForbidden) {
                substituteSettings.password = null;
                NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                doc.flush();
              }

              return ListView(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: Text(context.l10n.noSubstitutes),
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

class SubstituteMessageTab extends StatefulWidget {
  const SubstituteMessageTab({Key? key}) : super(key: key);

  @override
  State<SubstituteMessageTab> createState() => _SubstituteMessageTabState();
}

class _SubstituteMessageTabState extends State<SubstituteMessageTab> {
  @override
  Widget build(BuildContext context) {
    return StreamConsumer<SubstituteSettings>(
        doc: SubstituteSettings.get(),
        builder: (context, doc, substituteSettings) {
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ApiFutureBuilder<List<SubstituteMessage>>(
              request: getSubstituteMessages(substituteSettings.password!).build(),
              parser: SubstituteMessage.fromSubstituteMessages,
              dataBuilder: (substituteMessages, refresh, context) => ListView.separated(
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
                  NotificationSettings.get().load().then((value) => value.updateSubstitutes());
                  doc.flush();
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
        });
  }
}
