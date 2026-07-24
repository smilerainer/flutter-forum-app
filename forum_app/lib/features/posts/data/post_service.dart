import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';

class PostService {
  late final SupabaseClient _client;
  final DateTime Function() _now;

  PostService({SupabaseClient? client, DateTime Function()? now})
      : _client = client ?? SupabaseService.client,
        _now = now ?? DateTime.now;

  Future<Result<PaginatedResult<Post>>> fetchPosts({String? cursor, int limit = 10}) async {
    try {
      var query = _client
          .from('posts')
          .select('*, profiles(id, display_name, avatar_url, created_at), post_images(id, storage_path, position)');

      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

      final posts = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final items = (posts as List)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList();

      final hasMore = items.length == limit;
      final nextCursor = items.isEmpty ? null : items.last.createdAt.toIso8601String();

      return Success<PaginatedResult<Post>>(PaginatedResult(
        items: items,
        hasMore: hasMore,
        nextCursor: nextCursor,
      ));
    } on PostgrestException catch (e) {
      return Failure<PaginatedResult<Post>>(e.message);
    } catch (e) {
      return Failure<PaginatedResult<Post>>(e.toString());
    }
  }

  Future<Result<String>> createPost(String title, String? body) async {
    try {
      final now = _now();
      final result = await _client
          .from('posts')
          .insert({
            'title': title,
            'body': body,
            'user_id': _client.auth.currentUser?.id,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select('id')
          .single();

      return Success<String>(result['id'] as String);
    } on PostgrestException catch (e) {
      return Failure<String>(e.message);
    } catch (e) {
      return const Failure<String>('Failed to create post. Please try again.');
    }
  }

  Future<Result<void>> attachImages(String postId, List<String> storagePaths) async {
    try {
      final rows = storagePaths.asMap().entries.map((entry) {
        return {
          'post_id': postId,
          'storage_path': entry.value,
          'position': entry.key,
        };
      }).toList();

      await _client.from('post_images').insert(rows);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to attach images. Please try again.');
    }
  }

  Future<Result<void>> updatePost(String postId, String title, String? body) async {
    try {
      await _client
          .from('posts')
          .update({
            'title': title,
            'body': body,
            'updated_at': _now().toIso8601String(),
          })
          .eq('id', postId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to update post. Please try again.');
    }
  }

  Future<Result<void>> deletePost(String postId) async {
    try {
      final images = await _client
          .from('post_images')
          .select('storage_path')
          .eq('post_id', postId);

      final storage = StorageService(client: _client);
      for (final image in images) {
        final result = await storage.deleteFile(path: image['storage_path'] as String);
        if (result is Failure<void>) {
          return result;
        }
      }

      await _client.from('posts').delete().eq('id', postId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to delete post. Please try again.');
    }
  }
}