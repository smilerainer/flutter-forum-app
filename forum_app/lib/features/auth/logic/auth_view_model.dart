import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/result.dart';
import '../data/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  late final StreamSubscription<AuthState> _sub;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthViewModel(this._authService) {
    _user = _authService.currentUser;
    _sub = _authService.authStateChanges.listen((state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  Future<Result<void>> signIn(String email, String password) =>
      _authService.signIn(email: email, password: password);
  Future<Result<void>> signUp(String email, String password) =>
      _authService.signUp(email: email, password: password);
  Future<void> signOut() => _authService.signOut();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}