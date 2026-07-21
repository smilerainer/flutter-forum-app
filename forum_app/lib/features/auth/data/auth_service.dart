import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

class AuthService {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<Result<void>> signUp({required String email, required String password}) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Something went wrong. Please try again.');
    }
  }

  Future<Result<void>> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return const Success(null);
    } on AuthException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}