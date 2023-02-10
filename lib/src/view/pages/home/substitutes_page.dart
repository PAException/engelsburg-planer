import 'package:engelsburg_planer/src/backend/api/requests.dart';
import 'package:engelsburg_planer/src/models/api/dto/auth_response_dto.dart';
import 'package:engelsburg_planer/src/models/state/substitute_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/locked.dart';
import 'package:engelsburg_planer/src/view/widgets/substitute_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SubstitutesPage extends StatefulWidget {
  const SubstitutesPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SubstitutesPageState();
}

class _SubstitutesPageState extends State<SubstitutesPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  static int tabIndex = 0;
  DateFormat? formatter;
  Future<void>? fetching;
  bool _updatingScope = false;

  //TODO SubstituteService get _substituteController => context.data<SubstituteService>()!;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(initialIndex: tabIndex, length: 2, vsync: this);
    _pageController = PageController(initialPage: tabIndex);

    fetching = fetch();
  }

  Future<void> fetch() async {
    if (context.read<UserState>().loggedIn) {
      //TODO await _substituteController.updateSubstitutes(context.read<SubstituteSettings>());
      //TODO await _substituteController.updateSubstituteMessages();
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    formatter ??= DateFormat(
      'EEEE, dd.MM.',
      Localizations.localeOf(context).languageCode,
    );

    return Selector<UserState, bool>(
      selector: (context, auth) => auth.loggedIn,
      builder: (context, loggedIn, child) => loggedIn ? _buildPage(context) : const LockedScreen(),
    );
  }

  Widget _buildPage(BuildContext context) {
    return FutureBuilder(
      future: fetching,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        //TODO
        /*return _substituteController.isForbidden
            ? _buildSubstituteKeyPage()
            : Scaffold(
                appBar: TabBar(
                  indicatorColor: Theme.of(context).textTheme.bodyText1!.color,
                  labelColor: Theme.of(context).textTheme.bodyText1!.color,
                  onTap: (index) {
                    tabIndex = index;
                    _tabController.index = index;
                    _pageController.animateToPage(index,
                        duration: kTabScrollDuration, curve: Curves.ease);
                  },
                  controller: _tabController,
                  tabs: [
                    Tab(text: AppLocalizations.of(context)!.substitutes),
                    Tab(text: AppLocalizations.of(context)!.substituteMessages),
                  ],
                ),
                body: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: [
                    Consumer<SubstituteSettings>(
                      builder: (context, settings, child) => _buildSubstituteTab(settings),
                    ),
                    _buildSubstituteMessageTab(),
                  ],
                ),
              );
              */
        return Container();
      },
    );
  }

  Widget _buildSubstituteTab(SubstituteSettings settings) {
    //TODO var substitutes = _substituteController.substitutes;
    var substitutes = [];
    int addedSubstituteDates = 0;

    return RefreshIndicator(
      child: substitutes.isNotEmpty
          ? Padding(
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
                                    formatter!.format(substitutes[index].date!),
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
            )
          : ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Text(AppLocalizations.of(context)!.noSubstitutes),
                  ),
                ),
              ],
            ),
      onRefresh: () async {
        //TODO _substituteController.updateSubstitutes(settings);
        setState(() {});
      },
    );
  }

  Widget _buildSubstituteMessageTab() {
    //TODO var substituteMessages = _substituteController.substituteMessages;
    var substituteMessages = [];
    return RefreshIndicator(
      child: substituteMessages.isNotEmpty
          ? ListView.separated(
              itemBuilder: (context, index) => SubstituteMessageCard(
                substituteMessage: substituteMessages[index],
                formatter: formatter!,
              ),
              padding: const EdgeInsets.all(10),
              separatorBuilder: (context, index) => Container(height: 10),
              itemCount: substituteMessages.length,
            )
          : ListView(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Text(AppLocalizations.of(context)!.noSubstituteMessages),
                  ),
                ),
              ],
            ),
      onRefresh: () async {
        //TODO _substituteController.updateSubstituteMessages();
        setState(() {});
      },
    );
  }

  Widget _buildSubstituteKeyPage() {
    TextEditingController substituteKeyController = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context)!.verifyUserIsStudent,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            TextFormField(
              controller: substituteKeyController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: AppLocalizations.of(context)!.substitutesPassword,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
            Container(
              height: 64.0,
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (substituteKeyController.text.isEmpty) {
                    return;
                  }
                  setState(() {
                    _updatingScope = true;
                  });

                  var res = await requestScope({
                    "substitute.read.current": substituteKeyController.text,
                    "substitute.message.read.current": substituteKeyController.text,
                    "info.classes.read.all": substituteKeyController.text,
                    "info.teacher.read.all": substituteKeyController.text,
                  }).build().api(AuthResponseDTO.fromJson);

                  if (res.dataPresent) {
                    substituteKeyController.clear();
                    fetching = fetch();
                    setState(() {});
                  } else if (res.errorPresent) {
                    context.showL10nSnackBar((l10n) => l10n.wrongSubstituteKeyError);
                  }

                  setState(() {
                    _updatingScope = false;
                  });
                },
                child: _updatingScope
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CircularProgressIndicator(
                            color: Theme.of(context).buttonTheme.colorScheme!.surface,
                          ),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.check,
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
