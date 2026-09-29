import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tracker/database/app_database.dart';
import 'package:tracker/database/repositories/daily_completion_repository.dart';
import 'package:tracker/database/repositories/goal_repository.dart';
import 'package:tracker/routers/app_routers.dart';
import 'package:provider/provider.dart';
import 'package:tracker/services/ad_service.dart';
import 'package:tracker/services/alarm_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final adService = AdService();
final alarmService = AlarmService();
Future<void> main() async {
  final database = AppDatabase();
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();
  adService.loadInterstitialAd();
  await alarmService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),

        Provider<AdService>.value(value: adService),

        Provider<AlarmService>.value(value: alarmService),

        Provider<GoalRepository>(create: (_) => GoalRepository(database)),

        Provider<DailyCompletionRepository>(
          create: (_) => DailyCompletionRepository(database),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

void scheduleDailyLogReminder() {}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Tracker",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: AppRouters().appRouter,
    );
  }
}
