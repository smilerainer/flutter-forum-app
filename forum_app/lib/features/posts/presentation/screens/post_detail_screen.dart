import 'package:flutter/material.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

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
    _loadPost();
  }

  Future<void> _loadPost() async {
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
      ),
      body: _buildBody(),
    );
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
                  const Icon(Icons.person, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    post.author!.displayName ?? '(no displayName)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          if (post.body != null) ...[
            Text(
              post.body!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
          ],
          PostImageGrid(images: post.images),
          // Spacer for future comment section (Phase 5)
          const SizedBox(height: 200),
        ],
      ),
    );
  }
}