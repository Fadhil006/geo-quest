import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/google_login_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/team/team_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/map/map_screen.dart';
import 'presentation/screens/challenge/challenge_screen.dart';
import 'presentation/screens/leaderboard/leaderboard_screen.dart';
import 'presentation/screens/admin/admin_panel_screen.dart';
import 'presentation/screens/test/test_screen.dart';

/// Router provider — survives rebuilds, uses refreshListenable for auth changes
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier(ref);

  // Determine initial location based on mode
  final initialLocation = AppConfig.offlineMode ? '/register' : '/login';

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.matchedLocation;

      if (AppConfig.offlineMode) {
        // Legacy offline mode — original routing
        final isAuth = authState.status == AuthStatus.authenticated;
        final isAuthRoute =
            currentPath == '/login' || currentPath == '/register';
        if (!isAuth && !isAuthRoute) return '/register';
        if (isAuth && isAuthRoute) return '/home';
        return null;
      }

      // Online mode — Google Sign-In flow
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final needsTeam = authState.status == AuthStatus.needsTeam;
      final isLoginScreen = currentPath == '/login';
      final isTeamScreen = currentPath == '/team';
      final isAuthScreen = isLoginScreen ||
          currentPath == '/register' ||
          isTeamScreen;

      // Not signed in → go to login
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.unauthenticated ||
          authState.status == AuthStatus.error) {
        if (!isLoginScreen && currentPath != '/register') return '/login';
        return null;
      }

      // Signed in but no team → go to team screen
      if (needsTeam) {
        if (!isTeamScreen) return '/team';
        return null;
      }

      // Fully authenticated → redirect away from auth screens
      if (isAuthenticated && isAuthScreen) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => AppConfig.offlineMode
            ? const LoginScreen()
            : const GoogleLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/team',
        name: 'team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/challenge',
        name: 'challenge',
        builder: (context, state) => const ChallengeScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),
      GoRoute(
        path: '/test',
        name: 'test',
        builder: (context, state) => const TestScreen(),
      ),
    ],
  );
});

/// Notifier that triggers GoRouter redirect on auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

/// GeoQuest App Shell
class GeoQuestApp extends ConsumerWidget {
  const GeoQuestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GeoQuest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
