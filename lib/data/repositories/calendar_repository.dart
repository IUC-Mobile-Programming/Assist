import 'package:Assist/data/models/calendar_event.dart';
import 'package:flutter/material.dart';
import '../../core/extensions.dart';

abstract class CalendarRepository {
  Future<Map<DateTime, List<CalendarEvent>>> getEvents();
  Future<List<CalendarEvent>> getEventsForDate(DateTime date);
  Future<List<CalendarEvent>> getUpcomingEvents();
  Future<CalendarEvent> getEventById(String id);
  Future<String> addEvent(CalendarEvent event);
  Future<void> updateEvent(CalendarEvent event);
  Future<void> deleteEvent(String id);
}
