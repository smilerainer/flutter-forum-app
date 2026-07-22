import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';

class StorageService {
  final _client = SupabaseService.client;

  Future<Result<String>> uploadFile(String userId, Uint8List rawFile, String directory) async {
    const fileOptions = FileOptions(cacheControl: '3600', upsert: true);
    try{ 
      final String url = await _client.storage
        .from('images')
        .uploadBinary(directory,rawFile,fileOptions: fileOptions);
      return Success<String>(url);
    } on StorageException catch (e) {
      return Failure(e.message);
    } catch (_){
      return const Failure<String>('Upload failed. Please try again.'); 
    }
  }

  Future<Result<void>> deleteFile(String path) async {
    try {
      await _client.storage.from('bucket').remove([path]);
      return const Success<String>('Delete successful.');
    } catch (_) {
      return const Failure('Delete failed.');
  }
}

  Future<List<Result<String>>> uploadMany (String userId, String file) async {
    final List<Result<String>> results = [];
    return results; 
  }

  Future<List<Result<String>>> deleteMany (String userId, String file) async {
    final List<Result<String>> results = [];
    return results; 
  }
}