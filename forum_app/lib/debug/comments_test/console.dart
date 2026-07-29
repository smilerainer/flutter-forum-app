import 'package:flutter/material.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';
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
  final List<PickerImage> _pickedImages = [];

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
            _lastComment = data.items.isNotEmpty ? data.items.last : null;
          });
          return '${data.items.length} comments${data.items.isNotEmpty ? ', last: ${data.items.last.body ?? '(no text)'}' : ''}';
        }(),
        Failure<dynamic>(:final message) => throw Exception(message),
      };
    });
  }

  Future<String> _submitWithImages(String body) async {
    final postId = _selectedPost!.id;
    final commentBody = body.isEmpty ? null : body;

    final createResult = await _commentService.createComment(commentBody, postId);
    if (createResult is Failure<String>) {
      throw Exception(createResult.message);
    }

    final commentId = (createResult as Success<String>).data;
    var imageCount = 0;

    if (_pickedImages.isNotEmpty) {
      final storage = StorageService();
      final bytes = _pickedImages.map((i) => i.bytes).toList();
      final ext = _pickedImages.first.extension;
      final results = await storage.uploadFileBatch(
        bytes,
        directory: 'debug',
        extension: ext,
      );

      final paths = <String>[];
      for (final r in results) {
        switch (r) {
          case Success<String>(:final data):
            paths.add(data);
          case Failure<String>(:final message):
            throw Exception(message);
        }
      }

      if (paths.isNotEmpty) {
        final attachResult = await _commentService.attachImages(commentId, paths);
        if (attachResult is Failure<void>) {
          throw Exception(attachResult.message);
        }
        imageCount = paths.length;
      }
    }

    _pickedImages.clear();
    final msg = 'Comment $commentId created, $imageCount images attached';
    return msg;
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
        if (_selectedPost != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              children: [
                CommentInput(
                  key: const Key('comment_input'),
                  imagesCount: _pickedImages.length,
                  onSubmit: (body) async {
                    await run('Create Comment', () => _submitWithImages(body));
                  },
                ),
                const SizedBox(height: 8),
                 ImagePickerWidget(
                   onImagesChanged: (images) {
                     setState(() => _pickedImages
                       ..clear()
                       ..addAll(images));
                   },
                 ),
              ],
            ),
          ),
        if (_lastComment != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CommentTile(comment: _lastComment!),
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