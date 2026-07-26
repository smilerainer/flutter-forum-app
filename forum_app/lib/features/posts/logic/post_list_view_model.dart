import 'package:flutter/foundation.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';

class PostListViewModel extends ChangeNotifier {
  final PostService _postService;

  List<Post> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  String? _cursor;

  List<Post> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  PostListViewModel(this._postService);

  Future<void> loadInitial() async {
    _items = [];
    _cursor = null;
    _hasMore = true;
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _postService.fetchPosts(limit: 10);
      if (result is Success<PaginatedResult<Post>>) {
        _items = result.data.items;
        _hasMore = result.data.hasMore;
        _cursor = result.data.nextCursor;
        _error = null;
      } else if (result is Failure<PaginatedResult<Post>>) {
        _error = result.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _cursor == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _postService.fetchPosts(
        cursor: _cursor,
        limit: 10,
      );
      if (result is Success<PaginatedResult<Post>>) {
        _items = [..._items, ...result.data.items];
        _hasMore = result.data.hasMore;
        _cursor = result.data.nextCursor;
        _error = null;
      } else if (result is Failure<PaginatedResult<Post>>) {
        _error = result.message;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}