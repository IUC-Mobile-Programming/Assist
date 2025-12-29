import 'package:Assist/data/models/calendar_event.dart';
import 'package:Assist/data/repositories/calendar_repository.dart';

class GetEventsUseCase {
  final CalendarRepository repository;

  GetEventsUseCase(this.repository);

  Future<Map<DateTime, List<CalendarEvent>>> execute() async {
    return await repository.getEvents();
  }
}

class GetEventsForDateUseCase {
  final CalendarRepository repository;

  GetEventsForDateUseCase(this.repository);

  Future<List<CalendarEvent>> execute(DateTime date) async {
    return await repository.getEventsForDate(date);
  }
}

class GetUpcomingEventsUseCase {
  final CalendarRepository repository;

  GetUpcomingEventsUseCase(this.repository);

  Future<List<CalendarEvent>> execute() async {
    return await repository.getUpcomingEvents();
  }
}

class GetEventByIdUseCase {
  final CalendarRepository repository;

  GetEventByIdUseCase(this.repository);

  Future<CalendarEvent> execute(String id) async {
    return await repository.getEventById(id);
  }
}

class AddEventUseCase {
  final CalendarRepository repository;

  AddEventUseCase(this.repository);

  Future<String> execute(CalendarEvent event) async {
    return await repository.addEvent(event);
  }
}

class UpdateEventUseCase {
  final CalendarRepository repository;

  UpdateEventUseCase(this.repository);

  Future<void> execute(CalendarEvent event) async {
    return await repository.updateEvent(event);
  }
}

class DeleteEventUseCase {
  final CalendarRepository repository;

  DeleteEventUseCase(this.repository);

  Future<void> execute(String id) async {
    return await repository.deleteEvent(id);
  }
}