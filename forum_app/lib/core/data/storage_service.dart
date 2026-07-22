import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

class StorageService {
  late final SupabaseClient _client;
  final DateTime Function() _now;

  StorageService({SupabaseClient? client, DateTime Function()? now})
      : _client = client ?? SupabaseService.client,
        _now = now ?? DateTime.now;

  String _buildFilePath(String directory, String extension) {
    final fileName = '${_now().millisecondsSinceEpoch}.$extension';
    return '$directory/$fileName';
  }

  Future<Result<String>> uploadFile(Uint8List rawFile,
      {String? path, String? directory, String extension = 'png'}) async {
    const fileOptions = FileOptions(cacheControl: '3600', upsert: true);
    try {
      final targetPath = path ?? _buildFilePath(directory!, extension);
      final String url = await _client.storage
          .from('images')
          .uploadBinary(targetPath, rawFile, fileOptions: fileOptions);
      return Success<String>(url);
    } on StorageException catch (e) {
      return Failure(e.message);
    } catch (_) {
      return const Failure<String>('Upload failed. Please try again.');
    }
  }

  Future<Result<void>> deleteFile({
    String? path,
    String? directory,
    String? filename,
  }) async {
    final targetPath = path ?? '$directory/$filename';
    try {
      await _client.storage
          .from('images')
          .remove([targetPath]);
      return const Success<void>(null);
    } on StorageException catch (e) {
      return Failure<void>(e.message);
    } catch (_) {
      return const Failure<void>('Delete failed. Please try again.');
    }
  }

  Future<List<Result<String>>> uploadFileBatch(String userId, String file) async {
    final List<Result<String>> results = [];
    return results;
  }

  Future<List<Result<String>>> deleteFileBatch(String userId, String file) async {
    final List<Result<String>> results = [];
    return results;
  }
}