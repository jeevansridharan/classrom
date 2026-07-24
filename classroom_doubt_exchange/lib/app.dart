// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/post/post_doubt_screen.dart';
import 'screens/detail/question_detail_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/main_scaffold.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      if (!isLoggedIn && !onAuth) return '/login';
      if (isLoggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      // ── Auth routes (full-screen, no shell) ──────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _fadeTransition(
          state,
          const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (ctx, state) => _fadeTransition(
          state,
          const SignupScreen(),
        ),
      ),

      // ── Full-screen routes above the shell ────────────────────────────────
      GoRoute(
        path: '/post',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          const PostDoubtScreen(),
        ),
      ),
      GoRoute(
        path: '/question/:id',
        parentNavigatorKey: _rootKey,
        pageBuilder: (ctx, state) => _slideTransition(
          state,
          QuestionDetailScreen(questionId: state.pathParameters['id']!),
        ),
      ),

      // ── Shell (bottom nav) ────────────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (ctx, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            builder: (ctx, state) => const SearchScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (ctx, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (ctx, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── Page transition helpers ────────────────────────────────────────────────────
CustomTransitionPage<T> _fadeTransition<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<T> _slideTransition<T>(
    GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (ctx, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

// ── Root App Widget ────────────────────────────────────────────────────────────
class ClassroomDoubtApp extends ConsumerWidget {
  const ClassroomDoubtApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Classroom Doubt Exchange',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
