import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

FileObject _fakeFileObject(String name) => FileObject(
      name: name,
      bucketId: null,
      owner: null,
      id: null,
      updatedAt: null,
      createdAt: null,
      lastAccessedAt: null,
      metadata: null,
      buckets: null,
    );

void main() {
  late MockSupabaseClient mockClient;
  late MockSupabaseStorageClient mockStorage;
  late MockStorageFileApi mockFileApi;
  late StorageService service;

  const fileOptions = FileOptions(cacheControl: '3600', upsert: true);

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockStorage = MockSupabaseStorageClient();
    mockFileApi = MockStorageFileApi();

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
    test('returns Success when remove() reports at least one object removed', () async {
      when(() => mockFileApi.remove(['avatars/old.png']))
          .thenAnswer((_) async => [_fakeFileObject('old.png')]);

      final result = await service.deleteFile(path: 'avatars/old.png');

      expect(result, isA<Success<void>>());
      verify(() => mockFileApi.remove(['avatars/old.png'])).called(1);
    });

    test('builds path from directory + filename when no explicit path is given', () async {
      when(() => mockFileApi.remove(['avatars/old.png']))
          .thenAnswer((_) async => [_fakeFileObject('old.png')]);

      final result = await service.deleteFile(directory: 'avatars', filename: 'old.png');

      expect(result, isA<Success<void>>());
      verify(() => mockFileApi.remove(['avatars/old.png'])).called(1);
    });

    test('returns Failure when remove() reports zero objects removed (RLS-blocked or already gone)', () async {
      when(() => mockFileApi.remove(['avatars/old.png']))
          .thenAnswer((_) async => <FileObject>[]);

      final result = await service.deleteFile(path: 'avatars/old.png');

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure<void>).message,
        contains('No object was deleted'),
      );
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

  group('getPublicUrl', () {
    test('delegates to storage.from(bucket).getPublicUrl with the given path', () {
      when(() => mockFileApi.getPublicUrl('avatars/custom.png')).thenReturn(
          'https://project.supabase.co/storage/v1/object/public/images/avatars/custom.png');

      final url = service.getPublicUrl('avatars/custom.png');

      expect(url,
          'https://project.supabase.co/storage/v1/object/public/images/avatars/custom.png');
      verify(() => mockFileApi.getPublicUrl('avatars/custom.png')).called(1);
    });
  });

  group('uploadFileBatch', () {
    test('uploads every file and returns one Success per input, same order', () async {
      final files = [
        Uint8List.fromList([1]),
        Uint8List.fromList([2]),
        Uint8List.fromList([3]),
      ];
      when(() => mockFileApi.uploadBinary(any(), any(), fileOptions: fileOptions))
          .thenAnswer((invocation) async => invocation.positionalArguments[0] as String);

      final results = await service.uploadFileBatch(files, directory: 'post-images');

      expect(results, hasLength(3));
      expect(results.every((r) => r is Success<String>), isTrue);
      verify(() => mockFileApi.uploadBinary(any(), any(), fileOptions: fileOptions)).called(3);
    });

    test('a failure on one file does not stop the others', () async {
      final files = [
        Uint8List.fromList([1]),
        Uint8List.fromList([2]),
        Uint8List.fromList([3]),
      ];
      var callCount = 0;
      when(() => mockFileApi.uploadBinary(any(), any(), fileOptions: fileOptions))
          .thenAnswer((invocation) async {
        callCount++;
        if (callCount == 2) throw const StorageException('quota exceeded');
        return invocation.positionalArguments[0] as String;
      });

      final results = await service.uploadFileBatch(files, directory: 'post-images');

      expect(results[0], isA<Success<String>>());
      expect(results[1], isA<Failure<String>>());
      expect((results[1] as Failure<String>).message, 'quota exceeded');
      expect(results[2], isA<Success<String>>());
    });
  });

  group('deleteFileBatch', () {
    test('deletes every path and returns one Success per input when each remove() is non-empty', () async {
      final paths = ['posts/a.png', 'posts/b.png'];
      when(() => mockFileApi.remove(['posts/a.png']))
          .thenAnswer((_) async => [_fakeFileObject('a.png')]);
      when(() => mockFileApi.remove(['posts/b.png']))
          .thenAnswer((_) async => [_fakeFileObject('b.png')]);

      final results = await service.deleteFileBatch(paths);

      expect(results, hasLength(2));
      expect(results.every((r) => r is Success<void>), isTrue);
    });

    test('reports Failure for a path that matches zero objects, without failing the whole batch', () async {
      final paths = ['posts/a.png', 'posts/wrong-path.png'];
      when(() => mockFileApi.remove(['posts/a.png']))
          .thenAnswer((_) async => [_fakeFileObject('a.png')]);
      when(() => mockFileApi.remove(['posts/wrong-path.png']))
          .thenAnswer((_) async => <FileObject>[]);

      final results = await service.deleteFileBatch(paths);

      expect(results[0], isA<Success<void>>());
      expect(results[1], isA<Failure<void>>());
      expect((results[1] as Failure<void>).message, contains('No object was deleted'));
    });

    test('a StorageException on one path does not stop the others', () async {
      final paths = ['posts/a.png', 'posts/missing.png'];
      when(() => mockFileApi.remove(['posts/a.png']))
          .thenAnswer((_) async => [_fakeFileObject('a.png')]);
      when(() => mockFileApi.remove(['posts/missing.png']))
          .thenThrow(const StorageException('object not found'));

      final results = await service.deleteFileBatch(paths);

      expect(results[0], isA<Success<void>>());
      expect(results[1], isA<Failure<void>>());
      expect((results[1] as Failure<void>).message, 'object not found');
    });
  });
}
