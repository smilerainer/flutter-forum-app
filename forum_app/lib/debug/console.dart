import 'package:flutter/material.dart';

import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/comments/data/comment_service.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_input.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;

  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  final List<Post> _posts = [];
  Post? _selectedPost;
  Comment? _lastComment;

  Future<void> run(String label, Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      setState(() => _log.insert(0, '✅ $label → $result'));
    } catch (e) {
      setState(() => _log.insert(0, '❌ $label → $e'));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _fetchPosts() async {
    await run('Fetch Posts', () async {
      final result = await _postService.fetchPosts(limit: 20);
      return switch (result) {
        Success<PaginatedResult<Post>>(:final data) => () {
          setState(() {
            _posts
              ..clear()
              ..addAll(data.items);
            _selectedPost = _posts.isNotEmpty ? _posts.first : null;
          });
          return '${data.items.length} posts loaded';
        }(),
        Failure<PaginatedResult<Post>>(:final message) =>
          throw Exception(message),
      };
    });
  }

  Future<void> _fetchComments() async {
    if (_selectedPost == null) return;
    final postId = _selectedPost!.id;
    await run('Fetch Comments', () async {
      final result = await _commentService.fetchComments(postId);
      return switch (result) {
        Success<dynamic>(:final data) => () {
          setState(() {
            _lastComment = data.items.isNotEmpty ? data.items.first : null;
          });
          return '${data.items.length} comments, showing first';
        }(),
        Failure<dynamic>(:final message) => throw Exception(message),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton(
            key: const Key('comment_fetch_posts'),
            onPressed: _busy ? null : _fetchPosts,
            child: const Text('Fetch Posts'),
          ),
          ElevatedButton(
            key: const Key('comment_fetch_comments'),
            onPressed: (_busy || _selectedPost == null) ? null : _fetchComments,
            child: const Text('Show Comments'),
          ),
        ]),
        if (_posts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButton<Post>(
              value: _selectedPost,
              isExpanded: true,
              hint: const Text('Select a post'),
              items: _posts.map((p) => DropdownMenuItem(
                value: p,
                child: Text(
                  '${p.title} (${p.images.length} img)',
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (post) {
                if (post != null) setState(() => _selectedPost = post);
              },
            ),
          ),
        if (_lastComment != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CommentTile(comment: _lastComment!),
          ),
        if (_selectedPost != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: CommentInput(
              key: const Key('comment_input'),
              onSubmit: (body) async {
                await run('Create Comment', () async {
                  final result = await _commentService.createComment(body, _selectedPost!.id);
                  return switch (result) {
                    Success<String>(:final data) => 'Comment $data created',
                    Failure<String>(:final message) => throw Exception(message),
                  };
                });
              },
            ),
          ),
        const Divider(),
        Expanded(
          child: ListView(
            children: _log
                .map((l) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: SelectableText(
                        l,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }
}