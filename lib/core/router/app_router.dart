import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/workout/screens/workout_screen.dart';
import '../../features/workout/screens/workout_summary_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/routines/screens/routines_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../shared/widgets/atlas_bottom_nav.dart';
import 'route_names.dart';

final appRouter = GoRouter(
  initialLocation: RouteNames.dashboard,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AtlasScaffold(child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: RouteNames.progress,
          pageBuilder: (context, state) => const NoTransitionPage(child: ProgressScreen()),
        ),
        GoRoute(
          path: RouteNames.routines,
          pageBuilder: (context, state) => const NoTransitionPage(child: RoutinesScreen()),
        ),
        GoRoute(
          path: RouteNames.profile,
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.workout,
      builder: (context, state) => const WorkoutScreen(),
    ),
    GoRoute(
      path: RouteNames.workoutSummary,
      builder: (context, state) => const WorkoutSummaryScreen(),
    ),
  ],
);
