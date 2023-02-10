/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'package:engelsburg_planer/src/models/state/storable_change_notifier.dart';
import "package:flutter/material.dart";

/// Provided state to keep track of the current theme of the app.
class ThemeState extends StorableChangeNotifier<ThemeSettings> {
  ThemeState() : super("settings_theme", ThemeSettings.fromJson, ThemeSettings());

  ThemeData lightTheme() {
    return ThemeData.from(
      useMaterial3: true,
      colorScheme: const ColorScheme.light().copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
    );
  }

  ThemeData darkTheme() {
    return ThemeData.from(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark().copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
      ),
    );
  }

  /// Gets the current [ThemeMode].
  ThemeMode get mode => _modeFromString(current.mode);

  /// Gets the nullable primary color.
  Color? get primaryColor => _colorFromValue(current.primaryColor);

  /// Gets the nullable secondary color.
  Color? get secondaryColor => _colorFromValue(current.secondaryColor);

  /// Intern to set the theme mode, save and notify all listeners.
  void _setMode(String? mode) {
    current.mode = mode;

    save();
  }

  /// Set theme mode to DarkMode.
  void darkMode() => _setMode("dark");

  /// Set theme mode to LightMode.
  void lightMode() => _setMode("light");

  /// Set theme mode to the system default mode.
  void defaultMode() => _setMode(null);

  /// Set the primary color. If color to set is null the primary color will be removed.
  set primaryColor(Color? color) {
    current.primaryColor = color?.value;

    save();
  }

  /// Set the secondary color. If color to set is null the secondary color will be removed.
  set secondaryColor(Color? color) {
    current.secondaryColor = color?.value;

    save();
  }

  /// Determine [ThemeMode] by string
  ThemeMode _modeFromString(String? mode) {
    switch (mode) {
      case "dark":
        return ThemeMode.dark;
      case "light":
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  /// Nullable constructor of color.
  Color? _colorFromValue(int? value) => value != null ? Color(value) : null;
}

/// Class to save theme settings.
class ThemeSettings {
  String? mode;
  int? primaryColor;
  int? secondaryColor;

  ThemeSettings({
    this.mode,
    this.primaryColor,
    this.secondaryColor,
  });

  factory ThemeSettings.fromJson(dynamic json) {
    return ThemeSettings(
      mode: json["mode"],
      primaryColor: json["primaryColor"],
      secondaryColor: json["secondaryColor"],
    );
  }

  dynamic toJson() {
    return {
      "mode": mode,
      "primaryColor": primaryColor,
      "secondaryColor": secondaryColor,
    };
  }
}
