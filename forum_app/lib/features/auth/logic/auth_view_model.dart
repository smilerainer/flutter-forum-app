import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/result.dart';
import '../../../features/profile/data/profile_service.dart';
import '../../../features/profile/data/user_profile.dart';
import '../data/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final ProfileService _profileService;
  late final StreamSubscription<AuthState> _sub;

  User? _user;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool get isAdmin => _profile?.isAdmin ?? false;

  AuthViewModel(this._authService, {ProfileService? profileService})
      : _profileService = profileService ?? ProfileService() {
    _user = _authService.currentUser;
    _sub = _authService.authStateChanges.listen((state) async {
      _user = state.session?.user;
      notifyListeners();
      // Fetch profile when auth state changes so isAdmin is available
      if (_user != null) {
        await _loadProfile(_user!.id);
      } else {
        _profile = null;
      }
    });
  }

  Future<void> _loadProfile(String uid) async {
    final result = await _profileService.fetchProfile(uid);
    if (result is Success<UserProfile>) {
      _profile = result.data;
    } else {
      _profile = null;
    }
    notifyListeners();
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
