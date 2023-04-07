import 'dart:io' show Platform;

import 'package:engelsburg_planer/src/utils/constants/app_constants.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        var appStoreUrl = FirebaseRemoteConfig.instance.getString("app_store_url");
        var playStoreUrl = FirebaseRemoteConfig.instance.getString("play_store_url");
        var supportEmail = FirebaseRemoteConfig.instance.getString("support_email");

        return ListView(
          children: <Widget>[
            ListTile(
              leading: Image.asset(AssetPaths.appLogo),
              title: Text(
                packageInfo?.appName ?? context.l10n.loadingAppName,
              ),
              subtitle: Text(
                packageInfo?.version ?? context.l10n.loadingAppVersion,
              ),
            ),
            ListTile(
              title: Text(context.l10n.appDescription),
            ),
            const Divider(),
            if (appStoreUrl.isNotEmpty && playStoreUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.star_half),
                title: Text(context.l10n.rateApp),
                onTap: () => url_launcher.launchUrl(
                  Uri.parse(Platform.isIOS ? appStoreUrl : playStoreUrl),
                ),
              ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: Text(context.l10n.sendAnEmail),
              onTap: () => url_launcher.launchUrl(Uri.parse('mailto:$supportEmail')),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text(context.l10n.openSourceLicenses),
              onTap: () => showLicensePage(
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    AssetPaths.appLogo,
                    height: 64.0,
                  ),
                ),
                applicationName: packageInfo?.appName,
                applicationVersion: packageInfo?.version,
                context: context,
              ),
            ),
            const Divider(),
            ListTile(
                leading: const Icon(Icons.phone),
                title: Text(context.l10n.callPforte),
                onTap: () => url_launcher.launchUrl(Uri.parse('tel:${AppConstants.pforteNumber}'))),
            ListTile(
              leading: const Icon(Icons.phone),
              title: Text(context.l10n.callOffice),
              onTap: () => url_launcher.launchUrl(
                Uri.parse('tel:${AppConstants.sekretariatNumber}'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mail),
              title: Text(context.l10n.emailOffice),
              onTap: () => url_launcher.launchUrl(
                Uri.parse('mailto:${AppConstants.sekretariatEmail}'),
              ),
            ),
          ],
        );
      },
    );
  }
}
