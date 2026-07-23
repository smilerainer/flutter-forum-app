import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

import 'package:forum_app/features/profile/data/user_profile.dart';

class ProfileService {
  late final SupabaseClient _client;
  final DateTime Function() _now;
  ProfileService({SupabaseClient? client, DateTime Function()? now})
      : _client = client ?? SupabaseService.client,
        _now = now ?? DateTime.now;

  Future<Result<UserProfile>> fetchProfile(String uid) async {
    Map<String, dynamic> raw;
    try {
      raw = await _client
      .from('profiles')
      .select('display_name, avatar_url, created_at, updated_at')
      .filter('id', 'eq', uid)
      .maybeSingle() as Map<String, dynamic>;
      return Success(UserProfile(
        id: uid,
        display_name: raw['display_name'],
        avatar_url: raw['avatar_url'],
        created_at: DateTime.parse(raw['created_at'] as String),
        updated_at: DateTime.parse(raw['updated_at'] as String),
      ));
    } on PostgrestException catch(e){
      return Failure(e.message);
    } catch (_) {
      return Failure('Failed to fetch profile. Please try again.');
    }
  }

  Future<Result<void>> updateProfile(String uid, String newName) async {
    return Failure('Failed to update name. Please try again.');
  }

  Future<Result<void>> updateAvatar(String uid, String newPicturePath) async{
    return Failure('Failed to update name. Please try again.');
  }
}