import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

class StorageService {
  static const _bucket = 'images';

  late final SupabaseClient _client;
  final DateTime Function() _now;

  StorageService({SupabaseClient? client, DateTime Function()? now})
      : _client = client ?? SupabaseService.client,
        _now = now ?? DateTime.now;

  String _buildFilePath(String directory, String extension) {
    final fileName = '${_now().millisecondsSinceEpoch}.$extension';
    return '$directory/$fileName';
  }

  String getPublicUrl(String path) {
    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  Future<Result<String>> uploadFile(Uint8List rawFile, {
    String? path, String? directory, String extension = 'png',
  }) async {
    const fileOptions = FileOptions(cacheControl: '3600', upsert: true);
    try {
      final targetPath = path ?? _buildFilePath(directory!, extension);
      final storedPath = await _client.storage
          .from(_bucket)
          .uploadBinary(targetPath, rawFile, fileOptions: fileOptions);
      return Success<String>(storedPath.replaceFirst('images/', ''));
    } on StorageException catch (e) {
      return Failure<String>(e.message);
    } catch (_) {
      return const Failure<String>('Upload failed. Please try again.');
    }
  }

  Future<Result<void>> deleteFile({
  String? path, String? directory, String? filename,
  }) async {
    final targetPath = path ?? '$directory/$filename';
    try {
      final removed = await _client.storage
          .from('images')
          .remove([targetPath]);
      if (removed.isEmpty) {
        return const Failure<void>('No object was deleted. It may not exist or RLS blocked the operation.');
      }
      return const Success<void>(null);
    } on StorageException catch (e) {
      return Failure<void>(e.message);
    } catch (_) {
      return const Failure<void>('Delete failed. Please try again.');
    }
  }



  Future<List<Result<String>>> uploadFileBatch(
    List<Uint8List> files, {
    required String directory,
    String extension = 'png',
  }) async {
    final results = <Result<String>>[];
    for (final file in files) {
      results.add(
        await uploadFile(file, directory: directory, extension: extension),
      );
    }
    return results;
  }

  Future<List<Result<void>>> deleteFileBatch(List<String> paths) async {
    final results = <Result<void>>[];
    for (final path in paths) {
      final cleanPath = path.replaceFirst('images/', '');
      results.add(await deleteFile(path: cleanPath));
    }
    return results;
  }
}