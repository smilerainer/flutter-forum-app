import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:go_router/go_router.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.read<AuthViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (context.watch<AuthViewModel>().isLoggedIn)
                TextButton(
                  onPressed: () => authViewModel.signOut(),
                  child: const Text("Sign out"),
                )
              else 
                TextButton(
                onPressed: () => context.go('/login'),
                child: const Text("Log in"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}