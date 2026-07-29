import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/comments/data/comment_service.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';

class CommentViewModel extends ChangeNotifier {
  final CommentService _commentService;
  final StorageService _storageService;
  final String postId;

  List<Comment> _items = [];
  bool _isLoading = false;
  String? _error;

  List<Comment> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get error => _error;

  CommentViewModel(
    this.postId,
    this._commentService, {
    StorageService? storageService,
  }) : _storageService = storageService ?? StorageService();

  Future<void> loadComments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _commentService.fetchComments(postId);
      if (result is Success<PaginatedResult<Comment>>) {
        _items = result.data.items;
        _error = null;
      } else if (result is Failure<PaginatedResult<Comment>>) {
        _error = result.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> editComment(String commentId, String? newBody) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _commentService.updateComment(commentId, newBody);
      if (result is Failure<void>) {
        _error = result.message;
        notifyListeners();
        return;
      }

      final index = _items.indexWhere((c) => c.id == commentId);
      if (index != -1) {
        final old = _items[index];
        _items[index] = Comment(
          id: old.id,
          body: newBody,
          postId: old.postId,
          userId: old.userId,
          images: old.images,
          author: old.author,
          createdAt: old.createdAt,
        );
      }
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteComment(String commentId) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _commentService.deleteComment(commentId);
      if (result is Failure<void>) {
        _error = result.message;
        notifyListeners();
        return;
      }

      _items.removeWhere((c) => c.id == commentId);
    } finally {
      notifyListeners();
    }
  }

  Future<void> addComment(String body, List<XFile> images) async {
    _error = null;
    notifyListeners();

    try {
      final createResult = await _commentService.createComment(body, postId);
      if (createResult is Failure<String>) {
        _error = createResult.message;
        notifyListeners();
        return;
      }

      final commentId = (createResult as Success<String>).data;

      if (images.isNotEmpty) {
        final paths = <String>[];
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final ext = image.name.contains('.')
              ? image.name.split('.').last
              : 'png';
          final uploadResult = await _storageService.uploadFile(
            bytes,
            directory: 'comments/$commentId',
            extension: ext,
          );
          if (uploadResult is Success<String>) {
            paths.add(uploadResult.data);
          } else if (uploadResult is Failure<String>) {
            _error = uploadResult.message;
            notifyListeners();
            return;
          }
        }

        if (paths.isNotEmpty) {
          final attachResult = await _commentService.attachImages(
            commentId,
            paths,
          );
          if (attachResult is Failure<void>) {
            _error = attachResult.message;
            notifyListeners();
            return;
          }
        }
      }

      final newComment = Comment(
        id: commentId,
        body: body,
        postId: postId,
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        images: List.generate(
          images.length,
          (i) => ImageRef(
            id: 'tmp_${commentId}_$i',
            storagePath: images[i].name.contains('.')
                ? 'comments/$commentId/${images[i].name}'
                : 'comments/$commentId/${images[i].name}.png',
            position: i,
          ),
        ),
        createdAt: DateTime.now(),
      );
      _items = [..._items, newComment];
    } finally {
      notifyListeners();
    }
  }
}
