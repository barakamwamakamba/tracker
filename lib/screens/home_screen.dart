import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tracker/database/repositories/daily_completion_repository.dart';
import 'package:tracker/database/repositories/goal_repository.dart';
import 'package:tracker/services/score_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final goalRepository = context.read<GoalRepository>();
    final completionRespository = context.read<DailyCompletionRepository>();
    final scoreService = ScoreService();

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder(
          stream: goalRepository.watchGoals(),
          builder: (context, goalSnapshot) {
            if (!goalSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final goals = goalSnapshot.data!
                .where((goal) => goal.isActive)
                .toList();

            debugPrint("$goals");

            return StreamBuilder(
              stream: completionRespository.watchCompletionForDate(today),
              builder: (context, completionSnapshot) {
                if (!completionSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final completions = completionSnapshot.data!;

                final completedGoals = goals.where((goal) {
                  return completions.any(
                    (completion) =>
                        completion.goalId == goal.id && completion.completed,
                  );
                }).length;

                final score = scoreService.calculateScore(
                  totalGoals: goals.length,
                  completedGoals: completedGoals,
                );

                final label = scoreService.getLabel(score);

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      Text("Good morning"),
                      const SizedBox(height: 5),
                      Text("Let's make today count."),

                      const SizedBox(height: 20),

                      Text("Today"),
                      const SizedBox(height: 5),

                      Text(_formateDate(today)),
                      const SizedBox(height: 20),

                      Text('${score.round()}%'),
                      Text(label),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today's Goals"),
                          Text('$completedGoals/ ${goals.length}'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      if (goals.isEmpty) _buildEmptyState(context),

                      ...goals.map((goal) {
                        final completed = completions.any(
                          (completion) =>
                              completion.goalId == goal.id &&
                              completion.completed,
                        );

                        return GoalCard(
                          title: goal.title,
                          completed: completed,
                          onTap: () async {
                            await completionRespository.toggleCompletion(
                              goalId: goal.id,
                              date: today,
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () {
          context.push("/add-goal-screen");
        },
        child: Icon(Icons.add, color: Colors.white, size: 25),
      ),
    );
  }

  String _formateDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Icon(Icons.flag_outlined, size: 45),
          const SizedBox(height: 5),
          Text("Add your first goal and start tracking your day."),
        ],
      ),
    );
  }
}

class GoalCard extends StatelessWidget {
  final String title;
  final bool completed;
  final VoidCallback onTap;

  const GoalCard({
    required this.title,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: completed
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: completed ? Colors.green : Colors.grey.shade400,
                width: 2,
              ),
              color: completed ? Colors.green : Colors.transparent,
            ),
            child: completed
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
        ),

        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            decoration: completed ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          completed ? "Completed" : "Mark  as done",
          style: TextStyle(
            color: completed ? Colors.green : Colors.grey.shade600,
          ),
        ),

        trailing: completed ? const Icon(Icons.check_circle) : null,
        onTap: onTap,
      ),
    );
  }
}
