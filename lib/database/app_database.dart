import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'table/goals.dart';
import 'table/daily_completions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Goals, DailyCompletions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'tracker'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 1) {
      }
    },
  );
}
