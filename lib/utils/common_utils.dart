import 'package:flutter/material.dart';

List<Widget> filterNullWidgets(List<Widget?> widgets) {
  return widgets.where((widget) => widget != null).cast<Widget>().toList();
}

List<Widget> filterEmptyWidgets(List<Widget> widgets) {
  return widgets.where((widget) => widget != null).toList();
}

String? getInitials(String? name) {
  if (name == null || name.isEmpty) {
    return null;
  }

  List<String> nameParts = name.split(' ');
  if (nameParts.isEmpty) {
    return null;
  }

  if (nameParts.length == 1) {
    return nameParts[0][0].toUpperCase();
  }

  return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
}

String formatNumber(num number) {
  return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

String formatCurrency(num amount) {
  return '$${formatNumber(amount)}';
}

String formatPercentage(num percentage) {
  return '${formatNumber(percentage)}%';
}

const APPBAR_HEIGHT = 80.0;
const NOTIFICATION_MESSAGE_HEIGHT = 24.0;

const TAB_HOME = 0;
const TAB_PLACES = 1;
const TAB_CHAT = 2;
const TAB_SETTINGS = 3;

abstract class Enum<T> {
  final T _value;
  const Enum(this._value);
  T get value => _value;
}

dynamic setValue(
  dynamic value, {
  dynamic def,
}) {
  if (value == null) {
    return def;
  }

  return value;
}

// @see https://github.com/flutter/flutter/issues/17862
List<Widget> filterNullWidgets(List<Widget> widgets) {
  if (widgets == null) {
    return null;
  }

  return widgets.where((child) => child != null).toList();
}
