import 'package:flutter/material.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedString(String format) {
    final day = this.day.toString().padLeft(2, '0');
    final month = this.month.toString().padLeft(2, '0');
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');

    return format
        .replaceAll('dd', day)
        .replaceAll('MM', month)
        .replaceAll('yyyy', year.toString())
        .replaceAll('HH', hour)
        .replaceAll('mm', minute);
  }

  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension TimeOfDayExtension on TimeOfDay {
  String format(BuildContext context) {
    return MaterialLocalizations.of(context).formatTimeOfDay(this);
  }

  bool isBefore(TimeOfDay other) {
    if (hour < other.hour) return true;
    if (hour == other.hour) return minute < other.minute;
    return false;
  }

  bool isAfter(TimeOfDay other) {
    return !isBefore(other) && !isSameAs(other);
  }

  bool isSameAs(TimeOfDay other) {
    return hour == other.hour && minute == other.minute;
  }
}