/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/backend/database/state/app_state.dart';
import 'package:engelsburg_planer/src/services/firebase/analytics.dart';
import 'package:engelsburg_planer/src/services/firebase/crashlytics.dart';
import 'package:engelsburg_planer/src/utils/constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:flutter/material.dart';
import 'package:engelsburg_planer/src/backend/database/nosql/model/settings/notification_settings.dart';
import 'package:engelsburg_planer/src/backend/database/state/user_state.dart';
import 'package:provider/provider.dart';
import 'package:engelsburg_planer/src/utils/global_context.dart';
import 'package:engelsburg_planer/src/view/widgets/app_icon.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({super.key});

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final GlobalKey<SelectUserTypeState> key = GlobalKey<SelectUserTypeState>();

  UserType? get selectedUserType => key.currentState!.userType;

  @override
  void initState() {
    super.initState();
    Analytics.introduction.begin();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      PageViewModel(
        title: context.l10n.welcomeToApp,
        body: context.l10n.welcomeAppDescription,
        image: const AppIcon(size: 2),
        decoration: PageDecoration(
          imagePadding: const EdgeInsets.only(top: 80),
          pageColor: Theme.of(context).canvasColor,
        ),
      ),
      PageViewModel(
        decoration: PageDecoration(
            titlePadding: const EdgeInsets.only(top: 64),
            pageColor: Theme.of(context).canvasColor,
            bodyAlignment: Alignment.topCenter),
        title: context.l10n.newFeatures,
        useScrollView: false,
        bodyWidget: Container(
          alignment: Alignment.topCenter,
          width: 600,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.library_books),
                title: Text(
                    "${context.l10n.news} (${context.l10n.notifications})"),
              ),
              ListTile(
                leading: const Icon(Icons.apps_outlined),
                title: Text(context.l10n.timetable),
              ),
              ListTile(
                leading: const Icon(Icons.assessment_outlined),
                title: Text(context.l10n.grades),
              ),
              ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(context.l10n.tasks),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: Text(
                    "${context.l10n.substitutes} (${context.l10n.notifications})"),
              ),
              /*
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(context.l10n.syncBetweenDevices),
              ),*/
              ListTile(title: Text(context.l10n.andALotMore)),
            ],
          ),
        ),
      ),
      PageViewModel(
        title: context.l10n.configure,
        useScrollView: true,
        decoration: PageDecoration(
          titlePadding: const EdgeInsets.only(top: 64),
          pageColor: Theme.of(context).canvasColor,
          bodyAlignment: Alignment.topCenter,
        ),
        bodyWidget: Container(
          alignment: Alignment.topCenter,
          width: 600,
          child: SelectUserType(key: key, onUpdate: () => setState(() {})),
        ),
      ),
    ];

    return Consumer<AppConfigState>(
      builder: (context, config, _) => IntroductionScreen(
        scrollPhysics: const ClampingScrollPhysics(),
        pages: pages,
        globalFooter: Text(context.l10n.developedBy).paddingOnly(bottom: 16),
        hideBottomOnKeyboard: true,
        resizeToAvoidBottomInset: false,
        next: Text(context.l10n.next).fontWeight(FontWeight.w600),
        done: Disabled(
          disabled: key.currentState?.userType == null,
          child: Text(context.l10n.done).fontWeight(FontWeight.w600),
        ),
        dotsDecorator: DotsDecorator(
          activeSize: const Size(18.0, 9.0),
          activeColor: Theme.of(context).colorScheme.primary,
          activeShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        ),
        onDone: () => onDone(config),
      ),
    );
  }

  void onDone(AppConfigState config) async {
    if (selectedUserType == null) return;
    Crashlytics.log("Configuring app for the first time...");
    if (key.currentState!.validate()) {
      String? extra;
      if (selectedUserType == UserType.student) {
        extra = key.currentState!.className;
      } else if (selectedUserType == UserType.teacher) {
        extra = key.currentState!.teacher;
      }

      final appConfiguration = AppConfiguration(
        userType: selectedUserType!,
        extra: extra,
      );

      GoRouter router = GoRouter.of(context);
      await config.configure(appConfiguration);
      NotificationSettings.ref()
          .defaultStorage(globalContext())
          .load()
          .then((value) => value.setEnabled(true));

      Analytics.introduction.complete();
      if (appConfiguration.userType == UserType.student) {
        router.go("/settings/subject?callbackUrl=/article");
      } else {
        router.go("/article");
      }
    }
  }
}

/// Widget content to be displayed to select the app type.
class SelectUserType extends StatefulWidget {
  const SelectUserType({required super.key, required this.onUpdate});

  final VoidCallback onUpdate;

  @override
  State<SelectUserType> createState() => SelectUserTypeState();
}

class SelectUserTypeState extends State<SelectUserType> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  UserType? _selectedUserType;

  bool validate() => _formKey.currentState!.validate();

  UserType? get userType => _selectedUserType;

  String get className => _classNameController.text;

  String get teacher => _teacherController.text;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Text(context.l10n.questionAppType)
              .textScale(1.4)
              .textAlignment(TextAlign.center),
          6.heightBox,
          Text(context.l10n.descriptionAppTypeConfiguration)
              .textAlignment(TextAlign.center),
          20.heightBox,
          buildUserTypeListTile(
            title: context.l10n.student,
            description: context.l10n.studentAppTypeDescription,
            appType: UserType.student,
            icon: Icons.school_outlined,
          ),
          buildUserTypeInput(
            controller: _classNameController,
            hint: context.l10n.classNameInputHint,
            appType: UserType.student,
            validator: (value) {
              if (_selectedUserType == UserType.student &&
                  value != null &&
                  value.length < 2) {
                return context.l10n.invalidClassname;
              }

              return null;
            },
          ),
          buildUserTypeListTile(
            title: context.l10n.teacher,
            description: context.l10n.teacherAppTypeDescription,
            appType: UserType.teacher,
            icon: Icons.portrait,
          ),
          buildUserTypeInput(
            controller: _teacherController,
            hint: context.l10n.teacherAbbreviationInputHint,
            appType: UserType.teacher,
            validator: (value) {
              if (_selectedUserType == UserType.teacher &&
                  value != null &&
                  value.length < 3) {
                return context.l10n.invalidAbbreviation;
              }

              return null;
            },
          ),
          buildUserTypeListTile(
            title: context.l10n.other,
            description: context.l10n.otherAppTypeDescription,
            appType: UserType.other,
            icon: Icons.people_alt_outlined,
          ),
        ],
      ),
    );
  }

  /// Builds a list tile to select the app type
  ListTile buildUserTypeListTile({
    required String title,
    required String description,
    required UserType appType,
    required IconData icon,
  }) {
    return ListTile(
      minVerticalPadding: 8,
      selected: _selectedUserType == appType,
      minLeadingWidth: 50,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 40)],
      ),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        setState(() => _selectedUserType = appType);
        widget.onUpdate.call();
      },
    );
  }

  /// Builds an input field to be located under an list tile to select the app type
  AnimatedContainer buildUserTypeInput({
    required TextEditingController controller,
    required String hint,
    required UserType appType,
    required FormFieldValidator<String> validator,
  }) {
    return AnimatedContainer(
      height: _selectedUserType == appType ? 60 : 0,
      duration: kThemeAnimationDuration,
      child: Visibility(
        visible: _selectedUserType == appType,
        child: Padding(
          padding: const EdgeInsets.only(left: 80.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 280,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(hintText: hint),
                validator: validator,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stateful widget to select the app type
class SelectUserTypeDialog extends StatefulWidget {
  const SelectUserTypeDialog({super.key});

  @override
  State<SelectUserTypeDialog> createState() => _SelectUserTypeDialogState();
}

class _SelectUserTypeDialogState extends State<SelectUserTypeDialog> {
  var key = GlobalKey<SelectUserTypeState>();

  UserType? get selectedUserType => key.currentState!.userType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectUserType(
                key: key,
                onUpdate: () => setState(() {}),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(bottom: 16.0),
              alignment: Alignment.center,
              child: Disabled(
                disabled: key.currentState?.userType == null,
                child: TextButton(
                  onPressed: () async {
                    if (selectedUserType == null) return;
                    if (key.currentState!.validate()) {
                      String? extra;
                      if (selectedUserType == UserType.student) {
                        extra = key.currentState!.className;
                      } else if (selectedUserType == UserType.teacher) {
                        extra = key.currentState!.teacher;
                      }

                      final appConfiguration = AppConfiguration(
                        userType: selectedUserType!,
                        extra: extra,
                      );
                      GoRouter router = GoRouter.of(context);
                      await context
                          .read<AppConfigState>()
                          .configure(appConfiguration);

                      router.go("/");
                    }
                  },
                  child: Text(context.l10n.ok),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page to display to user for next steps after the app configuration is finished.
class WhatsNextPage extends StatelessWidget {
  const WhatsNextPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => context.navigate("/"),
            icon: const Icon(Icons.clear),
            color: context.theme.colorScheme.onBackground,
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  AssetPaths.appLogo,
                  height: 140,
                ),
                10.heightBox,
                Text(context.l10n.whatsNext)
                    .textScale(3)
                    .letterSpacing(5)
                    .fontWeight(FontWeight.w600)
                    .toCenter(),
                30.heightBox,
                Text(context.l10n.loginForAdvancedFeatures)
                    .textScale(1.2)
                    .textAlignment(TextAlign.center)
                    .toCenter(),
                15.heightBox,
                Text(context.l10n.noLoginForFewFeatures)
                    .textScale(1.2)
                    .textAlignment(TextAlign.center)
                    .toCenter(),
                40.heightBox,
                ElevatedButton(
                  onPressed: () => context.navigate("/signIn"),
                  child: Text(context.l10n.signIn)
                      .paddingSymmetric(vertical: 10, horizontal: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
