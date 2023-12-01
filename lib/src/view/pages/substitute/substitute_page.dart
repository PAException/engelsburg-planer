/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/api/model/teacher.dart';
import 'package:engelsburg_planer/src/backend/api/requests.dart';

import 'package:engelsburg_planer/src/backend/database/cache/session_persistent_data.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/substitute_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/special/storage/stream_selector.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_key_page.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_message_tab.dart';
import 'package:engelsburg_planer/src/view/pages/substitute/substitute_tab.dart';

class SubstitutesPage extends StatelessWidget {
  const SubstitutesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamSelector<SubstituteSettings, bool>(
      doc: SubstituteSettings.ref().defaultStorage(context),
      selector: (substituteSettings) => substituteSettings.password != null,
      builder: (context, doc, settings, value) {
        //Update teachers if substitute password is set
        if (value) updateTeachers(settings);

        return value ? const SubstitutePageContent() : const SubstituteKeyPage();
      },
    );
  }

  void updateTeachers(SubstituteSettings settings) async {
    if (SessionPersistentData.isSet<Teachers>()) return;

    var request = getTeacher(settings.password!).build();
    var response = await request.api<Teachers>(Teachers.fromJson);
    if (response.dataNotPresent) return;

    SessionPersistentData.set(response.data!);
  }
}

class SubstitutePageContent extends StatefulWidget {
  const SubstitutePageContent({super.key});

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
                      textScaler: const TextScaler.linear(2),
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
                      textScaler: const TextScaler.linear(2),
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
