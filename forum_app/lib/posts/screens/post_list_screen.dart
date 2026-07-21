import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              TextButton(
                onPressed: () => context.read<AuthViewModel>().signOut(),
                child: const Text("Sign Out"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}