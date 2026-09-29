import 'package:drift/drift.dart';

class DailyCompletions extends Table {
  TextColumn get id => text().unique()();
  TextColumn get goalId => text()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
    {goalId, date},
  ];
}
