/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:convert';

import 'package:flutter/material.dart';

/// Authenticated response from the api that contains all important information to keep
/// an authenticated session with the server. This class should only be used to transfer the
/// information.
@immutable
class AuthResponseDTO {
  final String token;
  final String refreshToken;
  final String? email;
  final String username;
  final List<String> loginVia;
  final bool verified;

  const AuthResponseDTO({
    required this.token,
    required this.refreshToken,
    this.email,
    required this.username,
    required this.loginVia,
    required this.verified,
  });

  factory AuthResponseDTO.fromJson(dynamic json) => AuthResponseDTO(
        token: json["token"],
        refreshToken: json["refreshToken"],
        email: json["email"],
        username: json["username"],
        loginVia: json["loginVia"].map<String>((e) => e as String).toList(),
        verified: json["verified"],
      );

  Authentication toAuth() => Authentication(
        jwt: JWT(token),
        refreshToken: refreshToken,
        email: email,
        username: username,
        loginVia: loginVia,
        verified: verified,
      );
}

/// Class to handle authentication info of the user. Can be saved and restored.
@immutable
class Authentication {
  final JWT jwt;
  final String refreshToken;
  final String? email;
  final String username;
  final List<String> loginVia;
  final bool verified;

  const Authentication({
    required this.jwt,
    required this.refreshToken,
    this.email,
    required this.username,
    required this.loginVia,
    required this.verified,
  });

  factory Authentication.fromJson(dynamic json) {
    return Authentication(
      jwt: JWT(json["jwt"]),
      refreshToken: json["refreshToken"],
      email: json["email"],
      username: json["username"],
      loginVia: json["loginVia"].map<String>((e) => e as String).toList(),
      verified: json["verified"],
    );
  }

  dynamic toJson() {
    return {
      "jwt": jwt.raw,
      "refreshToken": refreshToken,
      "email": email,
      "username": username,
      "loginVia": loginVia,
      "verified": verified,
    };
  }
}

/// Simple JWT implementation for the payload claims
@immutable
class JWT {
  final String raw;
  late final dynamic claims;
  late final List<String> scopes;

  JWT(this.raw) {
    claims = base64UrlToJson(raw.split(".")[1]);
    scopes = decodeScopes(claims["scopes"]).toList();
  }
}

Iterable<String> decodeScopes(String encoded) sync* {
  encoded = encoded.replaceAll("+", "-.");
  String current = "";
  for (var char in encoded.codeUnits) {
    if (char != "-".codeUnitAt(0)) {
      current = current + String.fromCharCode(char);
    } else {
      yield current;
      var index = current.lastIndexOf(".");

      if (index < 0) {
        current = "";
      } else {
        current.substring(0, index);
      }
    }
  }
  yield current;
}

dynamic base64UrlToJson(String value) =>
    jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(value))));
