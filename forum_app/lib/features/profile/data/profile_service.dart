import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

import 'package:forum_app/features/profile/data/user_profile.dart';
import 'package:forum_app/core/data/storage_service.dart';

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
      .select('display_name, avatar_url, is_admin, created_at, updated_at')
      .filter('id', 'eq', uid)
      .maybeSingle() as Map<String, dynamic>;
      return Success(UserProfile(
        id: uid,
        displayName: raw['display_name'] as String?,
        avatarUrl: raw['avatar_url'] as String?,
        isAdmin: raw['is_admin'] as bool? ?? false,
        createdAt: DateTime.parse(raw['created_at'] as String),
        updatedAt: raw['updated_at'] != null
            ? DateTime.parse(raw['updated_at'] as String)
            : null,
      ));
    } on PostgrestException catch(e){
      // Fallback if is_admin column doesn't exist yet (pre-migration)
      try {
        raw = await _client
        .from('profiles')
        .select('display_name, avatar_url, created_at, updated_at')
        .filter('id', 'eq', uid)
        .maybeSingle() as Map<String, dynamic>;
        return Success(UserProfile(
          id: uid,
          displayName: raw['display_name'] as String?,
          avatarUrl: raw['avatar_url'] as String?,
          isAdmin: false,
          createdAt: DateTime.parse(raw['created_at'] as String),
          updatedAt: raw['updated_at'] != null
              ? DateTime.parse(raw['updated_at'] as String)
              : null,
        ));
      } on PostgrestException {
        return Failure(e.message);
      } catch (_) {
        return Failure('Failed to fetch profile. Please try again.');
      }
    } catch (_) {
      return Failure('Failed to fetch profile. Please try again.');
    }
  }

  Future<Result<void>> updateProfile(String uid, String newName) async {
    try {
      final result = await _client
        .from('profiles')
        .update({'display_name': newName, 'updated_at': _now().toIso8601String()})
        .eq('id', uid)
        .select('id');

      if ((result as List).isEmpty) {
        return const Failure('You are not authorized to modify this resource.');
      }

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Failed to update name. Please try again.');
    }
  }

  Future<Result<String>> updateAvatar(String uid, Uint8List bytes, {String extension = 'png'}) async {
    try {
      final storage = StorageService(client: _client);
      final result = await storage.uploadFile(bytes, directory: 'avatars', extension: extension);
      final path = switch (result) {
        Success<String>(:final data) => data,
        Failure<String>(:final message) => throw Exception(message),
      };
      final publicUrl = storage.getPublicUrl(path);
      final updateResult = await _client
        .from('profiles')
        .update({'avatar_url': publicUrl, 'updated_at': _now().toIso8601String()})
        .eq('id', uid)
        .select('id');

      if ((updateResult as List).isEmpty) {
        return const Failure('You are not authorized to modify this resource.');
      }

      return Success(publicUrl);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Failed to update avatar. Please try again.');
    }
  }

  Future<Result<void>> clearAvatar(String uid) async {
    try {
      final updateResult = await _client
        .from('profiles')
        .update({'avatar_url': null, 'updated_at': _now().toIso8601String()})
        .eq('id', uid)
        .select('id');

      if ((updateResult as List).isEmpty) {
        return const Failure('You are not authorized to modify this resource.');
      }

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure('Failed to remove avatar. Please try again.');
    }
  }

}
