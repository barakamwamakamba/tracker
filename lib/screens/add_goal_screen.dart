import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tracker/database/repositories/goal_repository.dart';
import 'package:tracker/services/ad_service.dart';
import 'package:tracker/services/alarm_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final TextEditingController _titleController = TextEditingController();
  // final TextEditingController _dateController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _startAlarmEnabled = false;
  bool _endAlarmEnabled = false;

  Future<void> addGoal() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      return;
    }

    try {
      final goalRepository = context.read<GoalRepository>();
      final adService = context.read<AdService>();
      final alarmService = context.read<AlarmService>();

      final int? startTime = _startTime == null
          ? null
          : (_startTime!.hour * 60) + _startTime!.minute;

      final int? endTime = _endTime == null
          ? null
          : (_endTime!.hour * 60) + _endTime!.minute;

      final goalId = await goalRepository.addGoal(
        title,
        startTime,
        endTime,
        _startAlarmEnabled,
        _endAlarmEnabled,
      );

      await alarmService.scheduleGoalAlarms(
        goalId: goalId,
        title: title,
        startTime: startTime,
        endTime: endTime,
        startAlarmEnabled: _startAlarmEnabled,
        endAlarmEnabled: _endAlarmEnabled,
      );

      if (!mounted) return;

      await adService.showInterstitialAd();

      if (!mounted) return;

      context.pop();
    } catch (e) {
    }
  }

  Future<void> _selectedStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (selected == null) return;

    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _selectedEndtime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );

    if (selected == null) return;

    setState(() {
      _endTime = selected;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _titleController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Goal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),

        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: "Enter Title"),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(),
              width: double.infinity,
              child: const Text(
                "Remind me at start",
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.start,
              ),
            ),

            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("Start Time"),
              subtitle: Text(
                _startTime == null ? "Not set" : _startTime!.format(context),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _selectedStartTime();
              },
            ),

            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text("End Time"),
              subtitle: Text(
                _endTime == null ? "Not set" : _endTime!.format(context),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _selectedEndtime();
              },
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Remind me at start"),
              value: _startAlarmEnabled,
              onChanged: _startTime == null
                  ? null
                  : (value) {
                      setState(() {
                        _startAlarmEnabled = value;
                      });
                    },
            ),
            const SizedBox(height: 10),

            SwitchListTile(
              title: const Text("Remind me at finish"),
              value: _endAlarmEnabled,
              onChanged: _endTime == null
                  ? null
                  : (value) {
                      setState(() {
                        _endAlarmEnabled = value;
                      });
                    },
            ),

            const SizedBox(height: 10),

            // TextField(controller: _dateController, keyboardType: Type.calender),
            InkWell(
              onTap: addGoal,
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(color: Colors.green.shade500),
                child: Text(
                  "Create Goal",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
