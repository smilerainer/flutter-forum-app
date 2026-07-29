import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/core/widgets/author_tile.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_section.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Post? initialPost;

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _postService = PostService();

  Post? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _isLoading = false;
    }
    _loadPost();
  }

  Future<void> _loadPost() async {
    if (_post != null && _isLoading == false) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _postService.getPost(widget.postId);

    if (!mounted) return;

    if (result is Success<Post>) {
      setState(() {
        _post = result.data;
        _isLoading = false;
      });
    } else if (result is Failure<Post>) {
      setState(() {
        _error = result.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post?.title ?? 'Post'),
        actions: [
          if (_post != null && _isOwnPost(_post!)) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final result = await context.push<Post>('/posts/${_post!.id}/edit');
                if (result != null && mounted) {
                  setState(() => _post = result);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: _showDeletePostDialog,
              tooltip: 'Delete post',
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  bool _isOwnPost(Post post) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && post.userId == currentUserId;
  }

  Future<void> _showDeletePostDialog() async {
    final post = _post!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('Are you sure you want to delete this post? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final result = await _postService.deletePost(post.id);

    if (!mounted) return;

    if (result is Success<void>) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
      context.go('/posts');
    } else if (result is Failure<void>) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadPost, child: const Text('Retry')),
          ],
        ),
      );
    }

    final post = _post!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.author != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  if (post.author != null) {
                    context.push('/profile/${post.author!.id}');
                  }
                },
                child: AuthorTile(author: post.author),
              ),
            ),
          if (post.body != null && post.body!.isNotEmpty) ...[
            Text(post.body!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
          ],
          PostImageGrid(images: post.images, compact: true),
          CommentSection(postId: post.id),
        ],
      ),
    );
  }
}
