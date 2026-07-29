import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';
import 'package:forum_app/features/profile/logic/profile_view_model.dart';

class MockProfileService extends Mock implements ProfileService {}

class MockAuthViewModel extends Mock implements AuthViewModel {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  group('ProfileViewModel', () {
    late MockProfileService mockProfileService;
    late MockAuthViewModel mockAuthViewModel;
    late MockStorageService mockStorageService;

    setUp(() {
      mockProfileService = MockProfileService();
      mockAuthViewModel = MockAuthViewModel();
      mockStorageService = MockStorageService();
    });

    test('load() sets profile and clears isLoading when success', () async {
      final now = DateTime.now();
      when(() => mockAuthViewModel.user).thenReturn(
        User(id: 'user-1', appMetadata: {}, userMetadata: null, aud: '', createdAt: ''),
      );
      when(() => mockProfileService.fetchProfile('user-1')).thenAnswer(
        (_) async => Success(UserProfile(
          id: 'user-1',
          displayName: 'Test User',
          avatarUrl: null,
          createdAt: now,
          updatedAt: null,
        )),
      );

      final vm = ProfileViewModel(
        profileService: mockProfileService,
        authViewModel: mockAuthViewModel,
        storageService: mockStorageService,
      );

      await vm.load();

      expect(vm.profile, isNotNull);
      expect(vm.profile!.id, 'user-1');
      expect(vm.profile!.displayName, 'Test User');
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
    });

    test('updateName calls service and updates profile displayName', () async {
      final now = DateTime.now();
      when(() => mockAuthViewModel.user).thenReturn(
        User(id: 'user-1', appMetadata: {}, userMetadata: null, aud: '', createdAt: ''),
      );
      when(() => mockProfileService.updateProfile('user-1', 'New Name'))
          .thenAnswer((_) async => const Success(null));

      final vm = ProfileViewModel(
        profileService: mockProfileService,
        authViewModel: mockAuthViewModel,
        storageService: mockStorageService,
      );

      vm.profile = UserProfile(
        id: 'user-1',
        displayName: 'Old Name',
        avatarUrl: null,
        createdAt: now,
        updatedAt: null,
      );

      await vm.updateName('New Name');

      verify(() => mockProfileService.updateProfile('user-1', 'New Name')).called(1);
      expect(vm.profile!.displayName, 'New Name');
      expect(vm.isSaving, isFalse);
      expect(vm.error, isNull);
    });

    test('updateName with empty string does NOT call service', () async {
      final now = DateTime.now();
      when(() => mockAuthViewModel.user).thenReturn(
        User(id: 'user-1', appMetadata: {}, userMetadata: null, aud: '', createdAt: ''),
      );

      final vm = ProfileViewModel(
        profileService: mockProfileService,
        authViewModel: mockAuthViewModel,
        storageService: mockStorageService,
      );

      vm.profile = UserProfile(
        id: 'user-1',
        displayName: 'Old Name',
        avatarUrl: null,
        createdAt: now,
        updatedAt: null,
      );

      await vm.updateName('   ');

      verifyNever(() => mockProfileService.updateProfile(any(), any()));
      expect(vm.profile!.displayName, 'Old Name');
      expect(vm.error, 'Display name cannot be empty.');
    });

    test('removeAvatar sets avatarUrl to null', () async {
      final now = DateTime.now();
      when(() => mockAuthViewModel.user).thenReturn(
        User(id: 'user-1', appMetadata: {}, userMetadata: null, aud: '', createdAt: ''),
      );
      when(() => mockStorageService.deleteFile(path: any(named: 'path')))
          .thenAnswer((_) async => const Success(null));
      when(() => mockProfileService.clearAvatar(any()))
          .thenAnswer((_) async => const Success(null));

      final vm = ProfileViewModel(
        profileService: mockProfileService,
        authViewModel: mockAuthViewModel,
        storageService: mockStorageService,
      );

      vm.profile = UserProfile(
        id: 'user-1',
        displayName: 'Test',
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: now,
        updatedAt: null,
      );

      await vm.removeAvatar();

      expect(vm.profile!.avatarUrl, isNull);
      expect(vm.isSaving, isFalse);
      expect(vm.error, isNull);
    });
  });
}