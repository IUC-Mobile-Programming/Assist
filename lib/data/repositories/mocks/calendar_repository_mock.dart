import 'dart:async';
import 'package:flutter/material.dart';
import 'package:Assist/data/models/calendar_event.dart';
import 'package:Assist/data/repositories/calendar_repository.dart';
import 'package:Assist/core/extensions.dart';

class InMemoryCalendarRepository implements CalendarRepository {
  final Map<DateTime, List<CalendarEvent>> _events = {};

  InMemoryCalendarRepository() {
    _initializeSampleEvents();
  }

  void _initializeSampleEvents() {
    final today = DateTime.now();
    _events[DateTime(today.year, today.month, today.day)] = [
      CalendarEvent(
        title: 'Toplantı Hazırlığı',
        description: 'Sunum slaytlarını tamamla',
        startTime: const TimeOfDay(hour: 14, minute: 30),
        endTime: const TimeOfDay(hour: 15, minute: 30),
        date: today,
        color: Colors.blue,
      ),
      CalendarEvent(
        title: 'Spor Antrenmanı',
        description: 'Futbol antrenmanı - 19:00',
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 30),
        date: today,
        color: Colors.green,
      ),
    ];

    final tomorrow = today.add(const Duration(days: 1));
    _events[DateTime(tomorrow.year, tomorrow.month, tomorrow.day)] = [
      CalendarEvent(
        title: 'Doktor Randevusu',
        description: 'Check-up kontrolü',
        startTime: const TimeOfDay(hour: 10, minute: 0),
        endTime: const TimeOfDay(hour: 11, minute: 0),
        date: tomorrow,
        color: Colors.orange,
      ),
    ];
  }

  @override
  Future<Map<DateTime, List<CalendarEvent>>> getEvents() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return Map.from(_events);
  }

  @override
  Future<List<CalendarEvent>> getEventsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final key = DateTime(date.year, date.month, date.day);
    return _events[key] ?? [];
  }

  @override
  Future<List<CalendarEvent>> getUpcomingEvents() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final upcomingEvents = <CalendarEvent>[];

    _events.forEach((date, events) {
      if (date.isAfter(now) || date.isSameDay(now)) {
        upcomingEvents.addAll(events);
      }
    });

    return upcomingEvents;
  }

  @override
  Future<CalendarEvent> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (final events in _events.values) {
      final event = events.firstWhere((event) => event.id == id);
      return event.copyWith();
    }
    throw Exception('Event not found');
  }

  @override
  Future<String> addEvent(CalendarEvent event) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final key = DateTime(event.date.year, event.date.month, event.date.day);
    _events[key] ??= [];
    _events[key]!.add(event);
    return event.id;
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    await Future.delayed(const Duration(milliseconds: 500));
    await deleteEvent(event.id);
    await addEvent(event);
  }

  @override
  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _events.forEach((date, events) {
      events.removeWhere((event) => event.id == id);
    });
  }
}
