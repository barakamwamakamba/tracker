import 'package:tracker/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class DailyCompletionRepository {
  final AppDatabase db;

  DailyCompletionRepository(this.db);

  final _uuid = Uuid();

  DateTime _dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<DailyCompletion?> getCompletion({
    required String goalId,
    required DateTime date,
  }) {
    final day = _dayOnly(date);

    return (db.select(db.dailyCompletions)
          ..where((t) => t.goalId.equals(goalId) & t.date.equals(day)))
        .getSingleOrNull();
  }

  Future<void> markCompleted({required goalId, required DateTime date}) async {
    final day = _dayOnly(date);
    final completionId = _uuid.v4();

    final existing = await getCompletion(goalId: goalId, date: day);

    if (existing == null) {
      await db
          .into(db.dailyCompletions)
          .insert(
            DailyCompletionsCompanion.insert(
              id: completionId,
              goalId: goalId,
              date: day,
              completed: const Value(true),
            ),
          );
    } else {
      await (db.update(db.dailyCompletions)
            ..where((t) => t.id.equals(existing.id)))
          .write(const DailyCompletionsCompanion(completed: Value(true)));
    }
  }

  Future<void> markIncomplete({
    required String goalId,
    required DateTime date,
  }) async {
    final day = _dayOnly(date);
    final completionId = _uuid.v4();

    final existing = await getCompletion(goalId: goalId, date: day);

    if (existing == null) {
      await db
          .into(db.dailyCompletions)
          .insert(
            DailyCompletionsCompanion.insert(
              id: completionId,
              goalId: goalId,
              date: day,
              completed: const Value(false),
            ),
          );
    } else {
      await (db.update(db.dailyCompletions)
            ..where((tbl) => tbl.id.equals(existing.id)))
          .write(const DailyCompletionsCompanion(completed: Value(false)));
    }
  }

  Future<void> toggleCompletion({
    required String goalId,
    required DateTime date,
  }) async {
    final existing = await getCompletion(goalId: goalId, date: date);

    if (existing == null || !existing.completed) {
      await markCompleted(goalId: goalId, date: date);
    } else {
      await markIncomplete(goalId: goalId, date: date);
    }
  }

  Future<List<DailyCompletion>> getCompletionsBetween({
  required DateTime start,
  required DateTime end,
}) async {
  final startDay = _dayOnly(start);

  // End date is exclusive.
  final endExclusive = DateTime(
    end.year,
    end.month,
    end.day,
  ).add(const Duration(days: 1));

  return (db.select(db.dailyCompletions)
        ..where(
          (t) =>
              t.date.isBiggerOrEqualValue(startDay) &
              t.date.isSmallerThanValue(endExclusive),
        ))
      .get();
}


  Stream<List<DailyCompletion>> watchCompletionForDate(DateTime date) {
    final day = _dayOnly(date);

    return (db.select(
      db.dailyCompletions,
    )..where((t) => t.date.equals(day))).watch();
  }

  
}

//   Future<List<DailyCompletion>> getCompletionsForDate(
//     DateTime date,
//   ) {
//     final day = _dayOnly(date);

//     return (db.select(db.dailyCompletions)
//           ..where(
//             (tbl) => tbl.date.equals(day),
//           ))
//         .get();
//   }

//   Future<List<DailyCompletion>> getCompletionsForGoal(
//     int goalId,
//   ) {
//     return (db.select(db.dailyCompletions)
//           ..where(
//             (tbl) => tbl.goalId.equals(goalId),
//           )
//           ..orderBy([
//             (tbl) => OrderingTerm(
//                   expression: tbl.date,
//                   mode: OrderingMode.desc,
//                 ),
//           ]))
//         .get();
//   }
