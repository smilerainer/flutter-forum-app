import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseStorageClient mockStorage;
  late MockStorageFileApi mockFileApi;
  late StorageService service;

  const fileOptions = FileOptions(cacheControl: '3600', upsert: true);

  setUp(() {
    mockClient = MockSupabaseClient();
    mockStorage = MockSupabaseStorageClient();
    mockFileApi = MockStorageFileApi();

    // Wire the chain: client.storage -> from('images') -> fileApi
    when(() => mockClient.storage).thenReturn(mockStorage);
    when(() => mockStorage.from('images')).thenReturn(mockFileApi);

    service = StorageService(client: mockClient);
  });

  group('uploadFile', () {
    test('returns Success with the uploaded path when explicit path is given', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      when(() => mockFileApi.uploadBinary(
            'avatars/custom.png',
            bytes,
            fileOptions: fileOptions,
          )).thenAnswer((_) async => 'avatars/custom.png');

      final result = await service.uploadFile(bytes, path: 'avatars/custom.png');

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, 'avatars/custom.png');
      verify(() => mockFileApi.uploadBinary(
            'avatars/custom.png',
            bytes,
            fileOptions: fileOptions,
          )).called(1);
    });

    test('builds a deterministic path from directory + injected clock when no path is given', () async {
      final fixedNow = DateTime(2026, 1, 1, 12, 0, 0);
      final clockedService = StorageService(client: mockClient, now: () => fixedNow);
      final bytes = Uint8List.fromList([9, 9, 9]);
      final expectedPath = 'avatars/${fixedNow.millisecondsSinceEpoch}.png';

      when(() => mockFileApi.uploadBinary(
            expectedPath,
            bytes,
            fileOptions: fileOptions,
          )).thenAnswer((_) async => expectedPath);

      final result = await clockedService.uploadFile(bytes, directory: 'avatars');

      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, expectedPath);
      verify(() => mockFileApi.uploadBinary(
            expectedPath,
            bytes,
            fileOptions: fileOptions,
          )).called(1);
    });

    test('returns Failure with the Supabase message on StorageException', () async {
      final bytes = Uint8List.fromList([1]);
      when(() => mockFileApi.uploadBinary(
            'p/f.png',
            bytes,
            fileOptions: fileOptions,
          )).thenThrow(const StorageException('bucket not found'));

      final result = await service.uploadFile(bytes, path: 'p/f.png');

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).message, 'bucket not found');
    });

    test('returns a generic Failure on any other exception', () async {
      final bytes = Uint8List.fromList([1]);
      when(() => mockFileApi.uploadBinary(
            'p/f.png',
            bytes,
            fileOptions: fileOptions,
          )).thenThrow(Exception('network down'));

      final result = await service.uploadFile(bytes, path: 'p/f.png');

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).message, 'Upload failed. Please try again.');
    });
  });

  group('deleteFile', () {
    test('returns Success when explicit path is given', () async {
      when(() => mockFileApi.remove(['avatars/old.png']))
          .thenAnswer((_) async => <FileObject>[]);

      final result = await service.deleteFile(path: 'avatars/old.png');

      expect(result, isA<Success<void>>());
      verify(() => mockFileApi.remove(['avatars/old.png'])).called(1);
    });

    test('builds path from directory + filename when no explicit path is given', () async {
      when(() => mockFileApi.remove(['avatars/old.png']))
          .thenAnswer((_) async => <FileObject>[]);

      final result = await service.deleteFile(directory: 'avatars', filename: 'old.png');

      expect(result, isA<Success<void>>());
      verify(() => mockFileApi.remove(['avatars/old.png'])).called(1);
    });

    test('returns Failure with the Supabase message on StorageException', () async {
      when(() => mockFileApi.remove(['p/f.png']))
          .thenThrow(const StorageException('object not found'));

      final result = await service.deleteFile(path: 'p/f.png');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'object not found');
    });

    test('returns a generic Failure on any other exception', () async {
      when(() => mockFileApi.remove(['p/f.png'])).thenThrow(Exception('boom'));

      final result = await service.deleteFile(path: 'p/f.png');

      expect(result, isA<Failure<void>>());
      expect((result as Failure<void>).message, 'Delete failed. Please try again.');
    });
  });
}