import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';

class CommentService {
  late final SupabaseClient _client;
  final DateTime Function() _now;

  CommentService({SupabaseClient? client, DateTime Function()? now})
      : _client = client ?? SupabaseService.client,
        _now = now ?? DateTime.now;

  Future<Result<PaginatedResult<Comment>>> fetchComments(
    String postId, {
    String? cursor,
    int limit = 10,
  }) async {
    try {
      var query = _client
          .from('comments')
          .select('*, comment_images(id, storage_path, position), profiles(id, display_name, avatar_url, created_at)')
          .eq('post_id', postId);

      if (cursor != null) {
        query = query.lt('created_at', cursor);
      }

      final comments = await query
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .limit(limit);

      final items = (comments as List)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();

      final hasMore = items.length == limit;
      final nextCursor = items.isEmpty ? null : items.last.createdAt.toIso8601String();

      return Success<PaginatedResult<Comment>>(PaginatedResult(
        items: items,
        hasMore: hasMore,
        nextCursor: nextCursor,
      ));
    } on PostgrestException catch (e) {
      return Failure<PaginatedResult<Comment>>(e.message);
    } catch (e) {
      return Failure<PaginatedResult<Comment>>(e.toString());
    }
  }

  Future<Result<String>> createComment(String body, String postId) async {
    try {
      final now = _now();
      final result = await _client
          .from('comments')
          .insert({
            'body': body,
            'post_id': postId,
            'user_id': _client.auth.currentUser?.id,
            'created_at': now.toIso8601String(),
          })
          .select('id')
          .single();

      return Success<String>(result['id'] as String);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to create comment. Please try again.');
    }
  }

  Future<Result<void>> attachImages(String commentId, List<String> storagePaths) async {
    try {
      final rows = storagePaths.asMap().entries.map((entry) {
        return {
          'comment_id': commentId,
          'storage_path': entry.value,
          'position': entry.key,
        };
      }).toList();

      await _client.from('comment_images').insert(rows);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to attach images. Please try again.');
    }
  }

  Future<Result<void>> deleteComment(String commentId) async {
    try {
      final images = await _client
          .from('comment_images')
          .select('storage_path')
          .eq('comment_id', commentId);

      final storage = StorageService(client: _client);
      for (final image in images) {
        final result = await storage.deleteFile(path: image['storage_path'] as String);
        if (result is Failure<void>) {
          return result;
        }
      }

      await _client.from('comments').delete().eq('id', commentId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return Failure(e.message);
    } catch (e) {
      return const Failure('Failed to delete comment. Please try again.');
    }
  }
}