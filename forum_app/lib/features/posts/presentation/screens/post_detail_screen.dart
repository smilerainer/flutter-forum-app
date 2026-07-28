import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;
  final Post? initialPost;

  const PostDetailScreen({
    super.key,
    required this.postId,
    this.initialPost,
  });

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
          if (_post != null && _isOwnPost(_post!))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/posts/${_post!.id}/edit'),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  bool _isOwnPost(Post post) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    return currentUserId != null && post.userId == currentUserId;
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
            FilledButton(
              onPressed: _loadPost,
              child: const Text('Retry'),
            ),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: post.author!.avatarUrl != null
                        ? NetworkImage(post.author!.avatarUrl!)
                        : null,
                    child: post.author!.avatarUrl == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    post.author!.displayName ?? 'Unknown',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          if (post.body != null && post.body!.isNotEmpty) ...[
            Text(
              post.body!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
          PostImageGrid(images: post.images),
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}