/*
 * Copyright (c) Paul Huerkamp 2022. All rights reserved.
 */

import 'dart:async';
import 'dart:math';

import "package:awesome_extensions/awesome_extensions.dart";
import 'package:engelsburg_planer/src/models/db/subjects.dart';
import 'package:engelsburg_planer/src/models/state/user_state.dart';
import 'package:engelsburg_planer/src/view/widgets/util/util_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart' hide GoRouterHelper;
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

extension NumExtension on num {
  double roundToPlaces(int places) {
    num mod = pow(10.0, places);
    return ((this * mod).round().toDouble() / mod);
  }
}

extension DateTimeUtils on DateTime {
  bool isSameDay(DateTime other) => day == other.day && month == other.month && year == other.year;

  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  DateTime roundToDay() => copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  String elapsed(BuildContext context) {
    final difference = DateTime.now().difference(this);

    if ((difference.inDays / 365).floor() >= 1) {
      return context.l10n.yearsAgo((difference.inDays / 365).floor());
    } else if ((difference.inDays / 30).floor() >= 1) {
      return context.l10n.monthsAgo((difference.inDays / 30).floor());
    } else if ((difference.inDays / 7).floor() >= 1) {
      return context.l10n.weeksAgo((difference.inDays / 7).floor());
    } else if (difference.inDays >= 1) {
      return context.l10n.daysAgo((difference.inDays).floor());
    } else if (difference.inHours >= 1) {
      return context.l10n.hoursAgo((difference.inHours).floor());
    } else if (difference.inMinutes >= 1) {
      return context.l10n.minutesAgo((difference.inMinutes).floor());
    } else {
      return context.l10n.secondsAgo((difference.inSeconds).floor());
    }
  }

  operator <(DateTime other) => microsecondsSinceEpoch < other.microsecondsSinceEpoch;

  operator >(DateTime other) => microsecondsSinceEpoch > other.microsecondsSinceEpoch;

  operator <=(DateTime other) => microsecondsSinceEpoch <= other.microsecondsSinceEpoch;

  operator >=(DateTime other) => microsecondsSinceEpoch >= other.microsecondsSinceEpoch;

  String format(BuildContext context, String format) =>
      DateFormat(format, Localizations.localeOf(context).languageCode).format(this);

  String formatEEEEddMMToNow(BuildContext context) {
    String toNow = "";
    if (DateTime.now().subtract(const Duration(days: 1)).isSameDate(this)) {
      toNow = "${context.l10n.yesterday} - ";
    }
    if (isToday) toNow = "${context.l10n.today} - ";
    if (isTomorrow) toNow = "${context.l10n.tomorrow} - ";

    return toNow + formatEEEEddMM(context);
  }

  String formatEEEEddMM(BuildContext context) => format(context, "EEEE, dd.MM.");

  String formatEEEE(BuildContext context) => format(context, "EEEE");
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

  Future<List<C>> asyncMap<C>(Future<C> Function(T t) toElement) async =>
      await Future.wait(map(toElement));

  int count() => fold(0, (pre, _) => pre + 1);

  Iterable<C> mapIndex<C>(C Function(T element, int index) map) => Iterable.generate(
        length,
        (index) => map.call(elementAt(index), index),
      );

  Map<K, V> toMap<K, V>({required K Function(T) key, required V Function(T) value}) =>
      Map.fromEntries(map((e) => MapEntry(key.call(e), value.call(e))));
}

extension BuildContextExt on BuildContext {
  Future dialog(Widget dialog) => showDialog(context: this, builder: (_) => dialog);

  Future modalBottomSheet(Widget bottomSheet) => showModalBottomSheet(
        context: this,
        builder: (_) => bottomSheet,
      );

  AppLocalizations get l10n => AppLocalizations.of(this)!;

  void showL10nSnackBar(String Function(AppLocalizations l10n) localized) =>
      ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(localized.call(l10n))));

  bool get loggedIn => Provider.of<UserState>(this, listen: false).loggedIn;

  Color subjectColor(Subject? subject) =>
      subject?.parsedColor ?? Theme.of(this).textTheme.bodyLarge!.color!.withOpacity(0.15);

  /// Navigates to location, pushes all subpages
  void navigate(String location, {Object? extra}) => GoRouter.of(this).go(location, extra: extra);

  Future<dynamic> pushPage(Widget widget) {
    if ((widget is CompactStatelessWidget || widget is CompactStatefulWidget) &&
        isLandscape &&
        width > 500) {
      return showDialog(
        context: this,
        barrierDismissible: true,
        builder: (context) {
          return GestureDetector(
            onTap: context.pop,
            child: Container(
              alignment: Alignment.center,
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 500,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: widget,
                ),
              ),
            ),
          );
        },
      );
    } else {
      return push(widget);
    }
  }
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
