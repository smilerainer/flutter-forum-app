import 'package:flutter/foundation.dart';
import 'package:forum_app/debug/debug_console.dart';
import 'package:go_router/go_router.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/auth/presentation/screens/login_screen.dart';
import 'package:forum_app/features/auth/presentation/screens/register_screen.dart';
import 'package:forum_app/features/posts/presentation/screens/post_list_screen.dart';

String? authRedirect({required bool loggedIn, required String matchedLocation}) {
  final onAuthScreen = matchedLocation == '/login' || matchedLocation == '/register';
  final isPublicRoute = matchedLocation.startsWith('/posts');

  if (!loggedIn && !onAuthScreen && !isPublicRoute) return '/login';
  if (loggedIn && onAuthScreen) return '/posts';
  return null;
}

GoRouter buildRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: '/posts',
    refreshListenable: authViewModel,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/posts', builder: (context, state) => const PostListScreen()),
      if (kDebugMode) GoRoute(path: '/debug', builder: ((context, state) => const DebugConsole()))
    ],
    redirect: (context, state) => authRedirect(
      loggedIn: authViewModel.isLoggedIn,
      matchedLocation: state.matchedLocation,
    ),
  );
}