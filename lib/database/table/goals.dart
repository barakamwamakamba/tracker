import 'package:drift/drift.dart';

class Goals extends Table {
  TextColumn get id => text().unique()();

  TextColumn get title => text()();

  DateTimeColumn get createdAt => dateTime()();

  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();

  // Start time stored as minutes from midnight.
  // Example: 08:30 = 510
  IntColumn get startTime => integer().nullable()();

  // End time stored as minutes from midnight.
  // Example: 18:00 = 1080
  IntColumn get endTime => integer().nullable()();

  // Reminder at start time.
  BoolColumn get startAlarmEnabled =>
      boolean().withDefault(const Constant(false))();

  // Reminder at end time.
  BoolColumn get endAlarmEnabled =>
      boolean().withDefault(const Constant(false))();
}