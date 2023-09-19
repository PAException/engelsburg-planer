/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:awesome_extensions/awesome_extensions.dart';
import 'package:engelsburg_planer/src/utils/constants/asset_path_constants.dart';
import 'package:engelsburg_planer/src/utils/extensions.dart';
import 'package:engelsburg_planer/src/utils/oauth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:tap_debouncer/tap_debouncer.dart';

/// Button to wrap OAuth design and behavior.
class OAuthButton extends StatelessWidget {
  final OAuth oAuth;
  final OAuthType type;
  final MaterialStateProperty<Color?> backgroundColor;
  final MaterialStateProperty<Color?> foregroundColor;
  final Color borderColor;
  final Image icon;
  final String text;

  const OAuthButton({
    Key? key,
    required this.oAuth,
    required this.type,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    required this.text,
  }) : super(key: key);

  /// Google OAuth sign in button
  factory OAuthButton.google(BuildContext context) {
    return OAuthButton(
      oAuth: OAuth.google(),
      type: OAuthType.signIn,
      backgroundColor: MaterialStateProperty.all(Colors.white),
      foregroundColor: MaterialStateProperty.all(Colors.black),
      borderColor: Colors.black,
      icon: const Image(image: AssetImage(AssetPaths.googleLogo)),
      text: context.l10n.signInWithGoogle,
    );
  }

  static List<OAuthButton> getAll(BuildContext context) => [
        OAuthButton.google(context),
      ];

  static OAuthButton? byProviderId(BuildContext context, String providerId) =>
      getAll(context).firstNullableWhere((element) => element.oAuth.providerId == providerId);

  @override
  Widget build(BuildContext context) {
    return TapDebouncer(
      onTap: () => type.action(oAuth, () => context.navigate("/")),
      builder: (context, onTap) => ElevatedButton(
        onPressed: onTap,
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          padding: MaterialStateProperty.all(EdgeInsets.zero),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(width: 1, color: borderColor),
          ),
          child: onTap == null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SpinKitThreeBounce(
                    color: foregroundColor.resolve({MaterialState.selected}),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    icon,
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      width: 240,
                      height: 28,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(text).fontSize(18),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
