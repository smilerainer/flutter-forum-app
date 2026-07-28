import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forum_app/debug/console.dart';
import 'package:forum_app/debug/complete/index.dart';
import 'package:go_router/go_router.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/auth/presentation/screens/login_screen.dart';
import 'package:forum_app/features/auth/presentation/screens/register_screen.dart';
import 'package:forum_app/features/posts/presentation/screens/post_create_screen.dart';
import 'package:forum_app/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/presentation/screens/post_edit_screen.dart';
import 'package:forum_app/features/posts/presentation/screens/post_list_screen.dart';

String? authRedirect({required bool loggedIn, required String matchedLocation}) {
  final onAuthScreen = matchedLocation == '/login' || matchedLocation == '/register';
  final isPublicRoute = matchedLocation == '/posts' ||
      matchedLocation.startsWith('/posts/') &&
          matchedLocation != '/posts/create' &&
          !matchedLocation.endsWith('/edit') ||
      matchedLocation.startsWith('/debug');

  if (!loggedIn && !onAuthScreen && !isPublicRoute) return '/login';
  if (loggedIn && onAuthScreen) return '/posts';
  return null;
}

GoRouter buildRouter(AuthViewModel authViewModel, {GlobalKey<NavigatorState>? navigatorKey}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/posts',
    refreshListenable: authViewModel,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(path: '/posts', builder: (context, state) => const PostListScreen()),
      GoRoute(path: '/posts/create', builder: (context, state) => const PostCreateScreen()),
      GoRoute(
        path: '/posts/:id',
        builder: (context, state) =>
            PostDetailScreen(
              postId: state.pathParameters['id']!,
              initialPost: state.extra as Post?,
            ),
      ),
      GoRoute(
        path: '/posts/:id/edit',
        builder: (context, state) =>
            PostEditScreen(postId: state.pathParameters['id']!),
      ),
      if (kDebugMode) GoRoute(path: '/debug', builder: ((context, state) => const DebugConsole())),
      if (kDebugMode) GoRoute(path: '/debug/complete', builder: ((context, state) => const CompleteDebugConsole()))
    ],
    redirect: (context, state) => authRedirect(
      loggedIn: authViewModel.isLoggedIn,
      matchedLocation: state.matchedLocation,
    ),
  );
}