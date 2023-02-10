/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:engelsburg_planer/src/utils/oauth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ListTile to connect or disconnect an OAuth service.
class OAuthTile extends StatelessWidget {
  final OAuth oAuth;
  final String title;
  final Widget icon;

  const OAuthTile({
    Key? key,
    required this.oAuth,
    required this.title,
    required this.icon,
  }) : super(key: key);

  /// Google OAuth list tile
  factory OAuthTile.google() {
    return OAuthTile(
      oAuth: OAuth.google(),
      title: "Google",
      icon: const Padding(
        padding: EdgeInsets.all(12),
        child: Image(
          image: AssetImage(AssetPaths.googleLogo),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserState>(
      builder: (context, auth, child) {
        var oauth = auth.oauth(oAuth.providerId);

        bool connected = oauth != null;
        String display = oauth?.displayName ?? oauth?.email ?? oauth?.phoneNumber ?? "";

        return ListTile(
          title: Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Consumer<UserState>(
                    builder: (context, value, child) => Text(
                      "$title [$display]",
                      style: Theme.of(context).textTheme.bodyText2!.copyWith(
                          fontSize: 18,
                          color: connected
                              ? Theme.of(context).textTheme.headline6!.color
                              : Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          leading: icon,
          trailing: !connected
              ? const SizedBox(width: 0)
              : GestureDetector(
                  child: const Icon(Icons.clear_outlined),
                  onTap: () async {
                    await OAuthType.disconnect.action(context, oAuth);
                  },
                ),
          onTap: () async => connected ? null : await OAuthType.connect.action(context, oAuth),
        );
      },
    );
  }
}
