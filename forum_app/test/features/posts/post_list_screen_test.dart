import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/posts/presentation/screens/post_list_screen.dart';

class FakeAuthViewModel extends ChangeNotifier implements AuthViewModel {
  bool _loggedIn;
  FakeAuthViewModel({bool loggedIn = false}) : _loggedIn = loggedIn;

  @override
  bool get isLoggedIn => _loggedIn;

  @override
  User? get user => null;

  @override
  Future<void> signOut() async {
    _loggedIn = false;
    notifyListeners();
  }

  @override
  Future<Result<void>> signIn(String email, String password) async {
    _loggedIn = true;
    notifyListeners();
    return const Success(null);
  }

  @override
  Future<Result<void>> signUp(String email, String password) async {
    _loggedIn = true;
    notifyListeners();
    return const Success(null);
  }
}

void main() {
  Widget wrap(FakeAuthViewModel fake) => ChangeNotifierProvider<AuthViewModel>.value(
        value: fake,
        child: MaterialApp(home: const PostListScreen()),
      );

  testWidgets('shows Sign out when logged in', (tester) async {
    await tester.pumpWidget(wrap(FakeAuthViewModel(loggedIn: true)));
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
  });

  testWidgets('shows Log in when logged out', (tester) async {
    await tester.pumpWidget(wrap(FakeAuthViewModel(loggedIn: false)));
    expect(find.text('Log in'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
  });

  testWidgets('tapping Sign out flips state and updates UI', (tester) async {
    final fake = FakeAuthViewModel(loggedIn: true);
    await tester.pumpWidget(wrap(fake));

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(fake.isLoggedIn, isFalse);
    expect(find.text('Log in'), findsOneWidget);
  });
}