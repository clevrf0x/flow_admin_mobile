// lib/router/app_router.dart

import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/game_selection/game_selection_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
  ],
);
