import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

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
          final attachResult =
              await _commentService.attachImages(commentId, paths);
          if (attachResult is Failure<void>) {
            _error = attachResult.message;
            notifyListeners();
            return;
          }
        }
      }

      final reloadResult = await _commentService.fetchComments(postId);
      if (reloadResult is Success<PaginatedResult<Comment>>) {
        _items = reloadResult.data.items;
      }
    } finally {
      notifyListeners();
    }
  }
}