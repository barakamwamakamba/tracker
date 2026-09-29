import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tracker/database/app_database.dart';
import 'package:tracker/database/repositories/daily_completion_repository.dart';
import 'package:tracker/database/repositories/goal_repository.dart';
import 'package:tracker/services/score_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;

  List<Goal> _goals = [];
  List<DailyCompletion> _completions = [];

  final ScoreService _scoreService = ScoreService();

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
    });

    try {
      final goalRepository = context.read<GoalRepository>();
      final completionRepository = context.read<DailyCompletionRepository>();

      final goals = await goalRepository.getAllGoals();

      if (goals.isEmpty) {
        if (!mounted) return;

        setState(() {
          _goals = [];
          _completions = [];
          _loading = false;
        });

        return;
      }

      // Find the first month in which a goal existed.
      DateTime earliestDate = goals.first.createdAt;

      for (final goal in goals) {
        if (goal.createdAt.isBefore(earliestDate)) {
          earliestDate = goal.createdAt;
        }
      }

      final now = DateTime.now();

      final completions = await completionRepository.getCompletionsBetween(
        start: DateTime(
          earliestDate.year,
          earliestDate.month,
          earliestDate.day,
        ),
        end: DateTime(now.year, now.month, now.day),
      );

      if (!mounted) return;

      setState(() {
        _goals = goals;
        _completions = completions;
        _loading = false;
      });
    } catch (e) {
      debugPrint('History loading error: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  DateTime _dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Goal> _goalsForDate(DateTime date) {
    final day = _dayOnly(date);

    return _goals.where((goal) {
      final createdDay = _dayOnly(goal.createdAt);

      // A goal cannot be counted before it was created.
      return !createdDay.isAfter(day);
    }).toList();
  }

  List<DailyCompletion> _completionsForDate(DateTime date) {
    return _completions.where((completion) {
      return _isSameDay(completion.date, date);
    }).toList();
  }

  int _completedCount(DateTime date) {
    final goals = _goalsForDate(date);
    final completions = _completionsForDate(date);

    return goals.where((goal) {
      return completions.any(
        (completion) => completion.goalId == goal.id && completion.completed,
      );
    }).length;
  }

  double _score(DateTime date) {
    final goals = _goalsForDate(date);

    if (goals.isEmpty) {
      return 0;
    }

    final completed = _completedCount(date);

    return _scoreService.calculateScore(
      totalGoals: goals.length,
      completedGoals: completed,
    );
  }

  List<Goal> _missedGoals(DateTime date) {
    final goals = _goalsForDate(date);
    final completions = _completionsForDate(date);

    return goals.where((goal) {
      final completed = completions.any(
        (completion) => completion.goalId == goal.id && completion.completed,
      );

      return !completed;
    }).toList();
  }

  Color _scoreColor(DateTime date) {
    final goals = _goalsForDate(date);

    if (goals.isEmpty) {
      return Colors.grey.shade200;
    }

    final score = _score(date);

    if (score >= 80) {
      return Colors.green.shade500;
    }

    if (score >= 50) {
      return Colors.amber.shade500;
    }

    if (score > 0) {
      return Colors.red.shade400;
    }

    return Colors.grey.shade300;
  }

  Color _scoreTextColor(DateTime date) {
    final goals = _goalsForDate(date);

    if (goals.isEmpty) {
      return Colors.grey.shade600;
    }

    final score = _score(date);

    if (score >= 80) {
      return Colors.white;
    }

    if (score >= 50) {
      return Colors.black87;
    }

    if (score > 0) {
      return Colors.white;
    }

    return Colors.grey.shade700;
  }

  String _monthName(DateTime date) {
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

    return months[date.month - 1];
  }

  String _shortMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[date.month - 1];
  }

  String _weekdayName(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return weekdays[weekday - 1];
  }

  List<DateTime> _getMonths() {
    if (_goals.isEmpty) {
      return [];
    }

    DateTime earliest = _goals.first.createdAt;

    for (final goal in _goals) {
      if (goal.createdAt.isBefore(earliest)) {
        earliest = goal.createdAt;
      }
    }

    final firstMonth = DateTime(earliest.year, earliest.month);

    final now = DateTime.now();

    final lastMonth = DateTime(now.year, now.month);

    final months = <DateTime>[];

    var current = firstMonth;

    while (!current.isAfter(lastMonth)) {
      months.add(current);

      current = DateTime(current.year, current.month + 1);
    }

    // Display newest month first.
    return months.reversed.toList();
  }

  int _daysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  int _firstWeekday(DateTime month) {
    return DateTime(month.year, month.month, 1).weekday;
  }

  bool _isFuture(DateTime date) {
    final today = _dayOnly(DateTime.now());
    return date.isAfter(today);
  }

  Widget _buildMonthCalendar(DateTime month) {
    final daysInMonth = _daysInMonth(month);
    final firstWeekday = _firstWeekday(month);

    final cells = <Widget>[];

    // Empty cells before the first day.
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);

      final future = _isFuture(date);
      final goals = _goalsForDate(date);

      cells.add(
        _buildDayCell(date: date, future: future, hasGoals: goals.isNotEmpty),
      );
    }

    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            return Expanded(
              child: Center(
                child: Text(
                  _weekdayName(index + 1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 10),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            return cells[index];
          },
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool future,
    required bool hasGoals,
  }) {
    final today = _dayOnly(DateTime.now());
    final isToday = _isSameDay(date, today);

    if (future || !hasGoals) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Center(
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    final score = _score(date);
    final backgroundColor = _scoreColor(date);
    final textColor = _scoreTextColor(date);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${score.round()}%',
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissedGoals(DateTime month) {
    final daysInMonth = _daysInMonth(month);
    final today = _dayOnly(DateTime.now());

    final missedByDate = <DateTime, List<Goal>>{};

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);

      // Don't show future days.
      if (date.isAfter(today)) {
        continue;
      }

      final missed = _missedGoals(date);

      if (missed.isNotEmpty) {
        missedByDate[date] = missed;
      }
    }

    if (missedByDate.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No missed goals this month.',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Missed goals',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        ...missedByDate.entries.map((entry) {
          final date = entry.key;
          final goals = entry.value;

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_shortMonthName(date)} ${date.day}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                ...goals.map((goal) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Icon(
                          Icons.radio_button_unchecked,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMonthCard(DateTime month) {
    final monthGoals = _goals.where((goal) {
      return goal.createdAt.isBefore(DateTime(month.year, month.month + 1));
    }).toList();

    if (monthGoals.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_monthName(month)} ${month.year}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Text(
                '${monthGoals.length} '
                '${monthGoals.length == 1 ? 'goal' : 'goals'}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildMonthCalendar(month),

          const SizedBox(height: 20),

          _buildLegend(),

          const SizedBox(height: 20),

          _buildMissedGoals(month),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _legendItem(color: Colors.green.shade500, label: 'High'),
        _legendItem(color: Colors.amber.shade500, label: 'Average'),
        _legendItem(color: Colors.red.shade400, label: 'Low'),
        _legendItem(color: Colors.grey.shade300, label: 'Nothing'),
      ],
    );
  }

  Widget _legendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = _getMonths();

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(onPressed: _loadHistory, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _goals.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  const Text(
                    'Your progress',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Track your daily performance and missed goals.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 20),

                  ...months.map(_buildMonthCard),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 20),

            const Text(
              'No history yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Create your first goal and start tracking your progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
