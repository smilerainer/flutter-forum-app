import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

// ---------- Postgrest chain fakes ----------

class FakeTransform extends Mock implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  Map<String, dynamic>? _data;
  Object? _error;

  void setData(Map<String, dynamic>? data, Object? error) {
    _data = data;
    _error = error;
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(Map<String, dynamic>?)? onValue, {Function? onError}) {
    if (_error != null) throw _error!;
    return Future.value(onValue?.call(_data) as S?);
  }
}

class FakeFilterSelect extends Mock implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final FakeTransform _transform;

  FakeFilterSelect(this._transform);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> filter(
      String column, String operator, Object? value) {
    return this;
  }

  @override
  FakeTransform maybeSingle() => _transform;
}

class FakeFilterUpdate extends Mock implements PostgrestFilterBuilder<dynamic> {
  dynamic _eqError;

  void setEqError(dynamic error) {
    _eqError = error;
  }

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object? value) {
    if (_eqError != null) throw _eqError;
    return this;
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(dynamic)? onValue, {Function? onError}) {
    if (_eqError != null) return Future.error(_eqError!);
    return Future.value(onValue?.call(null) as S?);
  }
}

class FakeQueryBuilder extends Mock implements SupabaseQueryBuilder {
  final FakeFilterSelect selectFilter;
  final FakeFilterUpdate updateFilter;

  FakeQueryBuilder(this.selectFilter, this.updateFilter);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return selectFilter;
  }

  @override
  PostgrestFilterBuilder<dynamic> update(dynamic data) {
    return updateFilter;
  }
}

// ---------- Storage fakes ----------

class FakeStorageFileApi extends Mock implements StorageFileApi {}

class FakeSupabaseStorageClient extends Mock implements SupabaseStorageClient {
  final FakeStorageFileApi fileApi;

  FakeSupabaseStorageClient(this.fileApi);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == const Symbol('from')) return fileApi;
    return super.noSuchMethod(invocation);
  }
}

class FakeSupabaseClient extends Mock implements SupabaseClient {
  final FakeQueryBuilder queryBuilder;
  final FakeSupabaseStorageClient storageClient;

  FakeSupabaseClient(this.queryBuilder, this.storageClient);

  @override
  SupabaseQueryBuilder from(String table) => queryBuilder;

  @override
  SupabaseStorageClient get storage => storageClient;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ---------- Tests ----------

void main() {
  late FakeStorageFileApi fileApi;
  late FakeQueryBuilder fakeQueryBuilder;
  late FakeFilterSelect fakeFilterSelect;
  late FakeFilterUpdate fakeFilterUpdate;
  late FakeTransform fakeTransform;
  late FakeSupabaseStorageClient fakeStorageClient;
  late FakeSupabaseClient fakeClient;
  late ProfileService service;

  final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  setUp(() {
    fileApi = FakeStorageFileApi();
    fakeTransform = FakeTransform();
    fakeFilterSelect = FakeFilterSelect(fakeTransform);
    fakeFilterUpdate = FakeFilterUpdate();
    fakeQueryBuilder = FakeQueryBuilder(fakeFilterSelect, fakeFilterUpdate);
    fakeStorageClient = FakeSupabaseStorageClient(fileApi);
    fakeClient = FakeSupabaseClient(fakeQueryBuilder, fakeStorageClient);

    service = ProfileService(client: fakeClient, now: () => fixedNow);
  });

  group('fetchProfile', () {
    test('returns Success with UserProfile when query returns data', () async {
      fakeTransform.setData({
        'display_name': 'Alice',
        'avatar_url': 'https://example.com/alice.png',
        'created_at': fixedNow.toIso8601String(),
        'updated_at': fixedNow.toIso8601String(),
      }, null);

      final result = await service.fetchProfile('user-1');

      expect(result, isA<Success<UserProfile>>());
      final profile = (result as Success<UserProfile>).data;
      expect(profile.id, 'user-1');
      expect(profile.displayName, 'Alice');
      expect(profile.avatarUrl, 'https://example.com/alice.png');
      expect(profile.createdAt, fixedNow);
      expect(profile.updatedAt, fixedNow);
    });

    test('returns Failure with Postgrest message on PostgrestException', () async {
      fakeTransform.setData(null, PostgrestException(message: 'relation "profiles" does not exist'));

      final result = await service.fetchProfile('user-1');

      expect(result, isA<Failure<UserProfile>>());
      expect((result as Failure<UserProfile>).message, 'relation "profiles" does not exist');
    });

    test('returns generic Failure on any other exception', () async {
      fakeTransform.setData(null, Exception('timeout'));

      final result = await service.fetchProfile('user-1');

      expect(result, isA<Failure<UserProfile>>());
      expect((result as Failure<UserProfile>).message, 'Failed to fetch profile. Please try again.');
    });

    test('returns generic Failure when maybeSingle returns null', () async {
      fakeTransform.setData(null, null);

      final result = await service.fetchProfile('user-1');

      expect(result, isA<Failure<UserProfile>>());
      expect((result as Failure<UserProfile>).message, 'Failed to fetch profile. Please try again.');
    });
  });

  group('updateProfile', () {
    test('returns Success<void> and updates the row', () async {
      fakeFilterUpdate.setEqError(null);

      final result = await service.updateProfile('user-1', 'Bob');

      expect(result, isA<Success<void>>());
    });

    test('returns Failure with Postgrest message on PostgrestException', () async {
      fakeFilterUpdate.setEqError(PostgrestException(message: 'column "display_name" does not exist'));

      final result = await service.updateProfile('user-1', 'Bob');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'column "display_name" does not exist');
    });

    test('returns generic Failure on any other exception', () async {
      fakeFilterUpdate.setEqError(Exception('boom'));

      final result = await service.updateProfile('user-1', 'Bob');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'Failed to update name. Please try again.');
    });
  });

  group('updateAvatar', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('returns Success<void> when upload and profile update both succeed', () async {
      when(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenAnswer((_) async => 'images/avatars/user-1.png');
      when(() => fileApi.getPublicUrl(any())).thenReturn('https://example.com/avatars/user-1.png');
      fakeFilterUpdate.setEqError(null);

      final result = await service.updateAvatar('user-1', bytes);

      expect(result, isA<Success<void>>());
    });

    test('returns generic Failure when upload throws', () async {
      when(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenThrow(const StorageException('storage down'));
      fakeFilterUpdate.setEqError(null);

      final result = await service.updateAvatar('user-1', bytes);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'Failed to update avatar. Please try again.');
    });

    test('returns generic Failure when profile update throws after successful upload', () async {
      when(() => fileApi.uploadBinary(any(), any(), fileOptions: any(named: 'fileOptions')))
          .thenAnswer((_) async => 'images/avatars/user-1.png');
      when(() => fileApi.getPublicUrl(any())).thenReturn('https://example.com/avatars/user-1.png');
      fakeFilterUpdate.setEqError(Exception('network down'));

      final result = await service.updateAvatar('user-1', bytes);

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'Failed to update avatar. Please try again.');
    });
  });
}