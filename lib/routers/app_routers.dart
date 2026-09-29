import 'package:go_router/go_router.dart';
import 'package:tracker/screens/add_goal_screen.dart';
import 'package:tracker/screens/main_screen.dart';

class AppRouters {
  final GoRouter appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: "/", builder: (context, state) => MainScreen()),
      GoRoute(
        path: "/add-goal-screen",
        builder: (context, state) => AddGoalScreen(),
      ),
    ],
  );
}
