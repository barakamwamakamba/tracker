import 'dart:ffi';

import 'package:drift/drift.dart';
import 'package:tracker/database/app_database.dart';
import 'package:uuid/uuid.dart';

class GoalRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  GoalRepository(this.db);

  Future<String> addGoal(
    String title,
    int? startTime,
    int? endTime,
    bool startAlarmEnabled,
    bool endAlarmEnabled,
  ) async {
    final goalId = _uuid.v4();

    await db
        .into(db.goals)
        .insert(
          GoalsCompanion.insert(
            id: goalId,
            title: title,
            createdAt: DateTime.now(),
            startTime: Value(startTime),
            endTime: Value(endTime),
            startAlarmEnabled: Value(startAlarmEnabled),
            endAlarmEnabled: Value(endAlarmEnabled),
          ),
        );

    return goalId;
  }

  Future<List<Goal>> getAllGoals() {
    return db.select(db.goals).get();
  }

  Future<Goal?> getGoalById(String goalId) {
    return (db.select(
      db.goals,
    )..where((t) => t.id.equals(goalId))).getSingleOrNull();
  }

  Future<void> deleteGoal(String goalId) {
    return (db.delete(db.goals)..where((t) => t.id.equals(goalId))).go();
  }

  Stream<List<Goal>> watchGoals() {
    return db.select(db.goals).watch();
  }
}
