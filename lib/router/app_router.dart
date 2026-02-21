// lib/router/app_router.dart

import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/game_selection/game_selection_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/others/others_screen.dart';
import '../screens/change_password/change_password_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/today/today_screen.dart';
import '../screens/add_results/add_results_screen.dart';
import '../screens/daily_report/daily_report_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/game-selection',
      builder: (context, state) => const GameSelectionScreen(),
    ),
    GoRoute(
      path: '/dashboard/:gameId',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return DashboardScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/others',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return OthersScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/change-password',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return ChangePasswordScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/booking',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return BookingScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/settings',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return SettingsScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/today',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return TodayScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/add-results',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return AddResultsScreen(gameId: gameId, gameName: gameName);
      },
    ),
    GoRoute(
      path: '/dashboard/:gameId/daily-report',
      builder: (context, state) {
        final gameId = state.pathParameters['gameId']!;
        final gameName = state.uri.queryParameters['gameName'] ?? gameId;
        return DailyReportScreen(gameId: gameId, gameName: gameName);
      },
    ),
  ],
);
