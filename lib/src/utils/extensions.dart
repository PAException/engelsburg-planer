/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';
import 'dart:math';

import "package:awesome_extensions/awesome_extensions.dart";
import 'package:engelsburg_planer/src/models/state/network_state.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

const alphaNumericChars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

extension StringUtils on String {
  static String randomAlphaNumeric(int length) => String.fromCharCodes(
        Iterable.generate(
          length,
          (_) => alphaNumericChars.codeUnitAt(
            Random().nextInt(
              alphaNumericChars.length,
            ),
          ),
        ),
      );

  bool get isNumeric => double.tryParse(this) != null;

  bool get isBlank => RegExp(this).hasMatch("^\\s*\$");

  String? get nullIfBlank => isBlank ? null : this;
}

extension DateTimeUtils on DateTime {
  bool isSameDay(DateTime other) => day == other.day && month == other.month && year == other.year;

  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  //TODO: AppLocalizations
  String elapsed(BuildContext context) {
    final difference = DateTime.now().difference(this);

    if ((difference.inDays / 365).floor() >= 2) {
      return 'vor ${(difference.inDays / 365).floor()} Jahren';
    } else if ((difference.inDays / 365).floor() >= 1) {
      return 'vor 1 Jahr';
    } else if ((difference.inDays / 30).floor() >= 2) {
      return 'vor ${(difference.inDays / 30).floor()} Monaten';
    } else if ((difference.inDays / 30).floor() >= 1) {
      return 'vor 1 Monat';
    } else if ((difference.inDays / 7).floor() >= 2) {
      return 'vor ${(difference.inDays / 7).floor()} Wochen';
    } else if ((difference.inDays / 7).floor() >= 1) {
      return 'vor 1 Woche';
    } else if (difference.inDays >= 2) {
      return 'vor ${difference.inDays} Tagen';
    } else if (difference.inDays >= 1) {
      return 'vor 1 Tag';
    } else if (difference.inHours >= 2) {
      return 'vor ${difference.inHours} Stunden';
    } else if (difference.inHours >= 1) {
      return 'vor 1 Stunde';
    } else if (difference.inMinutes >= 2) {
      return 'vor ${difference.inMinutes} Minuten';
    } else if (difference.inMinutes >= 1) {
      return 'vor 1 Minute';
    } else if (difference.inSeconds >= 2) {
      return 'vor ${difference.inSeconds} Sekunden';
    } else {
      return 'vor einer Sekunde';
    }
  }

  String formatEEEEddMMToNow(BuildContext context) {
    String toNow = "";
    if (DateTime.now().subtract(const Duration(days: 1)).isSameDate(this)) {
      toNow = "${AppLocalizations.of(context)!.yesterday} - ";
    }
    if (isToday) toNow = "${AppLocalizations.of(context)!.today} - ";
    if (isTomorrow) toNow = "${AppLocalizations.of(context)!.tomorrow} - ";

    return toNow + formatEEEEddMM(context);
  }

  String formatEEEEddMM(BuildContext context) {
    return DateFormat('EEEE, dd.MM.', Localizations.localeOf(context).languageCode).format(this);
  }

  String formatEEEE(BuildContext context) {
    return DateFormat('EEEE', Localizations.localeOf(context).languageCode).format(this);
  }
}

extension ColorUtils on Color {
  static Color? fromHex(String? hex) {
    if (hex == null) return null;
    StringBuffer buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

extension ListUtils<T> on List<T> {
  T? nullableAt(int index) {
    if (index > length - 1) return null;

    return this[index];
  }
}

extension MapUtils<K, V> on Map<K, V> {
  List<T> mapToList<T>(T Function(K key, V value) map) {
    List<T> list = <T>[];
    forEach((key, value) => list.add(map.call(key, value)));

    return list;
  }
}

extension IteratorUtils<T> on Iterable<T> {
  int indexWhere(bool Function(T element) test) {
    int i = 0;
    for (var e in this) {
      if (test.call(e)) return i;
      i++;
    }

    return i;
  }

  int index(T element) => indexWhere((e) => e == element);

  T? firstNullableWhere(bool Function(T element) test) {
    for (var element in this) {
      if (test.call(element)) return element;
    }

    return null;
  }

  Iterable<T> replaceWhere(
    bool Function(T element) test,
    T Function(T old) replacement,
  ) {
    return Iterable.generate(
      length,
      (index) {
        var element = elementAt(index);
        if (test.call(element)) {
          return replacement.call(element);
        } else {
          return element;
        }
      },
    );
  }

  Iterable<T> peek(FutureOr<void> Function(T element) peek) {
    for (var element in this) {
      peek.call(element);
    }

    return this;
  }

  FutureOr<void> forIndexed(
    FutureOr<void>? Function(int index, T element) each, {
    bool reverse = false,
  }) async {
    if (!reverse) {
      for (var index = 0; index < length; index++) {
        await each.call(index, elementAt(index));
      }
    } else {
      for (var index = length - 1; index >= 0; index--) {
        await each.call(index, elementAt(index));
      }
    }
  }

  int count() => fold(0, (pre, _) => pre + 1);
}

extension BuildContextExt on BuildContext {
  Future dialog(Widget dialog) => showDialog(context: this, builder: (_) => dialog);

  Future modalBottomSheet(Widget bottomSheet) => showModalBottomSheet(
        context: this,
        builder: (_) => bottomSheet,
      );

  void showSnackBar(String msg) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(msg)));

  AppLocalizations get l10n => AppLocalizations.of(this)!;

  void showL10nSnackBar(String Function(AppLocalizations l10n) localized) =>
      showSnackBar(localized.call(l10n));

  void online() => read<NetworkState>().update(NetworkStatus.online);

  void loading() => read<NetworkState>().update(NetworkStatus.loading);

  void offline() => read<NetworkState>().update(NetworkStatus.offline);

  bool get loggedIn => Provider.of<UserState>(this, listen: false).loggedIn;
}

extension WidgetExt on Widget {
  Widget wrapIf({
    required bool value,
    required Widget Function(Widget child) wrap,
  }) {
    if (value) {
      return wrap.call(this);
    } else {
      return this;
    }
  }
}
