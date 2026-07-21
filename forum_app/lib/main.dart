import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:forum_app/core/env.dart';
import 'package:forum_app/features/auth/data/auth_service.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final authViewModel = AuthViewModel(AuthService());
  final router = buildRouter(authViewModel);

  runApp(MyApp(authViewModel: authViewModel, router: router));
}

class MyApp extends StatelessWidget {
  final AuthViewModel authViewModel;
  final GoRouter router;

  const MyApp({super.key, required this.authViewModel, required this.router});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }
}