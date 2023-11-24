/*
 * Copyright (c) Paul Huerkamp 2023. All rights reserved.
 */

import 'dart:io' show Platform;

import 'package:engelsburg_planer/src/utils/constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/view/widgets/app_icon.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final packageInfo = snapshot.data;
        var supportEmail = FirebaseRemoteConfig.instance.getString("support_email");

        String storeUrl = "";
        if (Platform.isIOS) {
          storeUrl = FirebaseRemoteConfig.instance.getString("app_store_url");
        } else if (Platform.isAndroid) {
          storeUrl = FirebaseRemoteConfig.instance.getString("play_store_url");
        }

        return ListView(
          children: <Widget>[
            ListTile(
              leading: const AppIcon(),
              title: Text(
                packageInfo?.appName ?? context.l10n.loadingAppName,
              ),
              subtitle: Text(
                packageInfo == null
                    ? context.l10n.loadingAppVersion
                    : "${packageInfo.version}+${packageInfo.buildNumber}",
              ),
            ),
            ListTile(
              title: Text(context.l10n.appDescription),
            ),
            const Divider(),
            if (storeUrl.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.star_half),
                title: Text(context.l10n.rateApp),
                onTap: () => url_launcher.launchUrl(
                  Uri.parse(storeUrl),
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
                applicationIcon: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AppIcon(size: 2),
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
