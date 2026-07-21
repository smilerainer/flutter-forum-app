import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/auth/presentation/screens/login_screen.dart';
import 'package:forum_app/features/auth/presentation/screens/register_screen.dart';

GoRouter buildRouter(AuthViewModel authViewModel) {
  return GoRouter(
    initialLocation: '/posts',
    refreshListenable: authViewModel,
    routes: [
      GoRoute(
        path: '/login', 
        builder: (context, state) => const LoginScreen()
      ),
      GoRoute(path: '/register', 
      builder: (context, state) => const RegisterScreen()
      ),
      GoRoute(
        path: '/posts',
        builder: (context, state) => const Scaffold(body: Center(child: Text('Posts placeholder'))),
      ),
    ],
    redirect: (context, state) {
      final loggedIn = authViewModel.isLoggedIn;
      final onAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isPublicRoute = state.matchedLocation.startsWith('/posts');

      if (!loggedIn && !onAuthScreen && !isPublicRoute) return '/login';
      if (loggedIn && onAuthScreen) return '/posts';
      return null;
    },
  );
}