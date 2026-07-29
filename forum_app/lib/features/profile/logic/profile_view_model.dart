import 'package:flutter/foundation.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class ProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;
  final AuthViewModel _authViewModel;
  final StorageService _storageService;

  UserProfile? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  ProfileViewModel({
    ProfileService? profileService,
    required AuthViewModel authViewModel,
    StorageService? storageService,
  })  : _profileService = profileService ?? ProfileService(),
        _authViewModel = authViewModel,
        _storageService = storageService ?? StorageService();

  Future<void> load({String? profileId}) async {
    final targetId = profileId ?? _authViewModel.user?.id;

    if (targetId == null) {
      error = _profileId == null || _profileId == _authViewModel.user?.id
          ? 'No user is currently signed in.'
          : 'Invalid user ID.';
      notifyListeners();
      return;
    }

    _profileId = profileId;
    isLoading = true;
    error = null;
    notifyListeners();

    final result = await _profileService.fetchProfile(targetId);

    isLoading = false;
    if (result is Success<UserProfile>) {
      profile = result.data;
    } else if (result is Failure<UserProfile>) {
      error = result.message;
    }

    notifyListeners();
  }

  String? _profileId;

  Future<void> updateName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      error = 'Display name cannot be empty.';
      notifyListeners();
      return;
    }

    final uid = _authViewModel.user?.id;
    if (uid == null) {
      error = 'No user is currently signed in.';
      notifyListeners();
      return;
    }

    isSaving = true;
    error = null;
    notifyListeners();

    final result = await _profileService.updateProfile(uid, trimmed);

    isSaving = false;

    if (result is Success<void>) {
      if (profile != null) {
        profile = UserProfile(
          id: profile!.id,
          displayName: trimmed,
          avatarUrl: profile!.avatarUrl,
          createdAt: profile!.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } else if (result is Failure<void>) {
      error = result.message;
    }

    notifyListeners();
  }

  Future<void> updateAvatar(Uint8List bytes, {String extension = 'png'}) async {
    final uid = _authViewModel.user?.id;
    if (uid == null) {
      error = 'No user is currently signed in.';
      notifyListeners();
      return;
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final uploadResult = await _profileService.updateAvatar(uid, bytes, extension: extension);

      isSaving = false;

      if (uploadResult is Success<String>) {
        if (profile != null) {
          profile = UserProfile(
            id: profile!.id,
            displayName: profile!.displayName,
            avatarUrl: uploadResult.data,
            createdAt: profile!.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      } else if (uploadResult is Failure<String>) {
        error = uploadResult.message;
      }
    } catch (e) {
      isSaving = false;
      error = 'Failed to update avatar. Please try again.';
    }

    notifyListeners();
  }

  Future<void> removeAvatar() async {
    final uid = _authViewModel.user?.id;
    if (uid == null) {
      error = 'No user is currently signed in.';
      notifyListeners();
      return;
    }

    isSaving = true;
    error = null;
    notifyListeners();

    try {
      final oldAvatarUrl = profile?.avatarUrl;

      if (oldAvatarUrl != null) {
        final storagePath = oldAvatarUrl.split('/').last;
        final fullPath = 'avatars/$storagePath';
        final deleteResult = await _storageService.deleteFile(path: fullPath);
        if (deleteResult is Failure<void>) {
          error = deleteResult.message;
          isSaving = false;
          notifyListeners();
          return;
        }
      }

      final result = await _profileService.clearAvatar(uid);

      isSaving = false;

      if (result is Success<void>) {
        if (profile != null) {
          profile = UserProfile(
            id: profile!.id,
            displayName: profile!.displayName,
            avatarUrl: null,
            createdAt: profile!.createdAt,
            updatedAt: DateTime.now(),
          );
        }
      } else if (result is Failure<void>) {
        error = result.message;
      }
    } catch (e) {
      isSaving = false;
      error = 'Failed to remove avatar. Please try again.';
    }

    notifyListeners();
  }
}