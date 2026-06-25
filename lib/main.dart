import 'package:flutter/material.dart';
import 'package:tracker/screens/home_screen.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.initHive();
  await NotificationService.init();

  runApp(const MyApp());
}

void scheduleDailyLogReminder() {
  NotificationService.dailyReminder(
    id: 0,
    hour: 10,
    minute: 00,
    body: 'Don’t forget to log your daily intake!',
    title: 'Daily Tracker',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: "Tracker",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
