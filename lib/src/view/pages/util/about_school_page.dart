import 'package:engelsburg_planer/src/utils/constants/app_constants.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutSchoolPage extends StatefulWidget {
  const AboutSchoolPage({Key? key}) : super(key: key);

  @override
  AboutSchoolPageState createState() => AboutSchoolPageState();
}

class AboutSchoolPageState extends State<AboutSchoolPage> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: Image.asset(AssetPaths.schoolImage),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32.0, bottom: 8.0),
          child: Text(
            AppLocalizations.of(context)!.info,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
          ),
        ),
        Text(AppLocalizations.of(context)!.schoolDescription),
        RichText(
            text: TextSpan(
                text: '${AppLocalizations.of(context)!.source}: ',
                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge!.color),
                children: [
              TextSpan(
                  text: AppConstants.schoolDescriptionSourceDomain,
                  style: const TextStyle(color: Colors.blue),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      url_launcher.launchUrl(Uri.parse(AppConstants.schoolDescriptionSourceUrl));
                    })
            ])),
        const Divider(thickness: 0, height: 30),
        ListTile(
            leading: const Icon(Icons.phone),
            title: Text(AppLocalizations.of(context)!.callPforte),
            onTap: () => url_launcher.launchUrl(Uri.parse('tel:${AppConstants.pforteNumber}'))),
        ListTile(
            leading: const Icon(Icons.phone),
            title: Text(AppLocalizations.of(context)!.callOffice),
            onTap: () =>
                url_launcher.launchUrl(Uri.parse('tel:${AppConstants.sekretariatNumber}'))),
        ListTile(
            leading: const Icon(Icons.mail),
            title: Text(AppLocalizations.of(context)!.emailOffice),
            onTap: () =>
                url_launcher.launchUrl(Uri.parse('mailto:${AppConstants.sekretariatEmail}'))),
      ],
    );
  }
}
