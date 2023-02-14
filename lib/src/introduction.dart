/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/models/state/app_state.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/util/conditioned.dart';
import 'package:engelsburg_planer/src/view/widgets/util/switch_expandable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

class IntroductionPage extends StatefulWidget {
  const IntroductionPage({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<IntroductionPage> createState() => _IntroductionPageState();
}

class _IntroductionPageState extends State<IntroductionPage> {
  final GlobalKey<SelectAppTypeState> key = GlobalKey<SelectAppTypeState>();

  AppType? get selectedAppType => key.currentState!.appType;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PageViewModel(
        title: context.l10n.welcomeToApp,
        body: context.l10n.welcomeAppDescription,
        image: Image.asset(AssetPaths.appLogo),
        decoration: const PageDecoration(imagePadding: EdgeInsets.only(top: 80)),
      ),
      PageViewModel(
        decoration: const PageDecoration(titlePadding: EdgeInsets.only(top: 40)),
        title: context.l10n.newFeatures,
        useScrollView: false,
        bodyWidget: Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.library_books),
                title: Text("${context.l10n.news} (${context.l10n.notifications})"),
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
                title: Text("${context.l10n.substitutes} (${context.l10n.notifications})"),
              ),
              ListTile(
                leading: const Icon(Icons.sync),
                title: Text(context.l10n.syncBetweenDevices),
              ),
              ListTile(title: Text(context.l10n.andALotMore)),
            ],
          ),
        ),
      ),
      PageViewModel(
        title: context.l10n.configure,
        useScrollView: false,
        decoration: const PageDecoration(titlePadding: EdgeInsets.only(top: 40)),
        bodyWidget: SelectAppType(key: key, onUpdate: () => setState(() {})),
      ),
    ];

    return Consumer<AppConfigurationState>(
      builder: (context, config, _) => Conditioned(
        condition: !config.isConfigured,
        otherwise: widget.child,
        child: IntroductionScreen(
          scrollPhysics: const ClampingScrollPhysics(),
          pages: pages,
          globalFooter: Text(context.l10n.developedBy).paddingOnly(bottom: 16),
          next: Text(context.l10n.next).fontWeight(FontWeight.w600),
          done: Disabled(
            disabled: key.currentState?.appType == null,
            child: Text(context.l10n.done).fontWeight(FontWeight.w600),
          ),
          dotsDecorator: DotsDecorator(
            activeSize: const Size(18.0, 9.0),
            activeColor: Theme.of(context).colorScheme.primary,
            activeShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
          ),
          onDone: () => onDone(config),
        ),
      ),
    );
  }

  void onDone(AppConfigurationState config) async {
    if (selectedAppType == null) return;
    if (key.currentState!.validate()) {
      String? extra;
      if (selectedAppType == AppType.student) {
        extra = key.currentState!.className;
      } else if (selectedAppType == AppType.teacher) {
        extra = key.currentState!.teacher;
      }

      final appConfiguration = AppConfiguration(
        appType: selectedAppType!,
        extra: extra,
      );
      var nav = Navigator.of(context);
      await config.configure(appConfiguration);

      //TODO set substitute settings

      nav.push(MaterialPageRoute(builder: (_) => const WhatsNextPage()));
    }
  }
}

/// Widget content to be displayed to select the app type.
class SelectAppType extends StatefulWidget {
  const SelectAppType({required Key? key, required this.onUpdate}) : super(key: key);

  final VoidCallback onUpdate;

  @override
  State<SelectAppType> createState() => SelectAppTypeState();
}

class SelectAppTypeState extends State<SelectAppType> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  AppType? _selectedAppType;

  bool validate() => _formKey.currentState!.validate();

  AppType? get appType => _selectedAppType;

  String get className => _classNameController.text;

  String get teacher => _teacherController.text;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        shrinkWrap: true,
        children: [
          Text(context.l10n.questionAppType).textScale(1.4).textAlignment(TextAlign.center),
          6.heightBox,
          Text(context.l10n.descriptionAppTypeConfiguration).textAlignment(TextAlign.center),
          20.heightBox,
          buildAppTypeListTile(
            title: context.l10n.student,
            description: context.l10n.studentAppTypeDescription,
            appType: AppType.student,
            icon: Icons.school_outlined,
          ),
          buildAppTypeInput(
            controller: _classNameController,
            hint: context.l10n.classNameInputHint,
            appType: AppType.student,
            validator: (value) {
              if (_selectedAppType == AppType.student && value != null && value.length < 2) {
                return context.l10n.invalidClassname;
              }

              return null;
            },
          ),
          buildAppTypeListTile(
            title: context.l10n.teacher,
            description: context.l10n.teacherAppTypeDescription,
            appType: AppType.teacher,
            icon: Icons.portrait,
          ),
          buildAppTypeInput(
            controller: _teacherController,
            hint: context.l10n.teacherAbbreviationInputHint,
            appType: AppType.teacher,
            validator: (value) {
              if (_selectedAppType == AppType.teacher && value != null && value.length < 3) {
                return context.l10n.invalidAbbreviation;
              }

              return null;
            },
          ),
          buildAppTypeListTile(
            title: context.l10n.other,
            description: context.l10n.otherAppTypeDescription,
            appType: AppType.other,
            icon: Icons.people_alt_outlined,
          ),
        ],
      ),
    );
  }

  /// Builds a list tile to select the app type
  ListTile buildAppTypeListTile({
    required String title,
    required String description,
    required AppType appType,
    required IconData icon,
  }) {
    return ListTile(
      minVerticalPadding: 8,
      selected: _selectedAppType == appType,
      minLeadingWidth: 50,
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 40)],
      ),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        setState(() => _selectedAppType = appType);
        widget.onUpdate.call();
      },
    );
  }

  /// Builds an input field to be located under an list tile to select the app type
  AnimatedContainer buildAppTypeInput({
    required TextEditingController controller,
    required String hint,
    required AppType appType,
    required FormFieldValidator<String> validator,
  }) {
    return AnimatedContainer(
      height: _selectedAppType == appType ? 60 : 0,
      duration: kThemeAnimationDuration,
      child: Visibility(
        visible: _selectedAppType == appType,
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
class SelectAppTypeDialog extends StatefulWidget {
  const SelectAppTypeDialog({Key? key}) : super(key: key);

  @override
  State<SelectAppTypeDialog> createState() => _SelectAppTypeDialogState();
}

class _SelectAppTypeDialogState extends State<SelectAppTypeDialog> {
  var key = GlobalKey<SelectAppTypeState>();

  AppType? get selectedAppType => key.currentState!.appType;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectAppType(
              key: key,
              onUpdate: () => setState(() {}),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 16.0),
            alignment: Alignment.center,
            child: Disabled(
              disabled: key.currentState?.appType == null,
              child: TextButton(
                onPressed: () async {
                  if (selectedAppType == null) return;
                  if (key.currentState!.validate()) {
                    String? extra;
                    if (selectedAppType == AppType.student) {
                      extra = key.currentState!.className;
                    } else if (selectedAppType == AppType.teacher) {
                      extra = key.currentState!.teacher;
                    }

                    final appConfiguration = AppConfiguration(
                      appType: selectedAppType!,
                      extra: extra,
                    );
                    GoRouter router = GoRouter.of(context);
                    await context.read<AppConfigurationState>().configure(appConfiguration);

                    //TODO set substitute settings?

                    router.go("/");
                  }
                },
                child: Text(context.l10n.ok),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page to display to user for next steps after the app configuration is finished.
class WhatsNextPage extends StatelessWidget {
  const WhatsNextPage({Key? key}) : super(key: key);

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
            onPressed: () => context.go("/"),
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
                  onPressed: () => context.go("/signIn"),
                  child: Text(context.l10n.signIn).paddingSymmetric(vertical: 10, horizontal: 40),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
