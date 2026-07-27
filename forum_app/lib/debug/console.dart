import 'package:flutter/material.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/paginated_result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/presentation/screens/post_edit_screen.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;

  final PostService _postService = PostService();
  final StorageService _storageService = StorageService();
  final List<Post> _posts = [];
  Post? _selectedPost;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

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

  void _openEdit() {
    if (_selectedPost == null) return;
    Navigator.push<Post>(
      context,
      MaterialPageRoute(
        builder: (_) => PostEditScreen(post: _selectedPost!),
      ),
    ).then((refreshed) {
      if (refreshed != null && mounted) {
        setState(() {
          _selectedPost = refreshed;
          final idx = _posts.indexWhere((p) => p.id == refreshed.id);
          if (idx >= 0) {
            _posts[idx] = refreshed;
          }
        });
        _log.insert(0, '✅ Edit returned → ${refreshed.title}');
      }
    });
  }

  Future<void> _removeImages() async {
    if (_selectedPost == null) return;
    final post = _selectedPost!;
    if (post.images.isEmpty) {
      await run('Remove Images', () async =>
        throw Exception('No images on this post'));
      return;
    }

    await run('Remove All Images from "${post.title}"', () async {
      // Delete storage files first
      for (final img in post.images) {
        final delResult = await _storageService.deleteFile(path: img.storagePath);
        if (delResult is Failure<void>) {
          return 'Storage delete failed: ${delResult.message}';
        }
      }

      // Remove post_images rows
      final ids = post.images.map((i) => i.id).toList();
      final removeResult = await _postService.removeImages(ids);
      return switch (removeResult) {
        Success<void> _ => '${ids.length} image(s) removed',
        Failure<void>(:final message) => throw Exception(message),
      };
    });
  }

  Future<void> _updatePost() async {
    if (_selectedPost == null) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      await run('Update Post', () async =>
        throw Exception('Enter a title first'));
      return;
    }
    final body = _bodyController.text.trim();

    await run('Update "${_selectedPost!.title}"', () async {
      final result = await _postService.updatePost(
        _selectedPost!.id,
        title,
        body.isEmpty ? null : body,
      );
      return switch (result) {
        Success<void> _ => 'Post updated',
        Failure<void>(:final message) => throw Exception(message),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        // Data operation buttons
        Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            ElevatedButton(
              onPressed: _busy ? null : _fetchPosts,
              child: const Text('Fetch Posts'),
            ),
            ElevatedButton(
              onPressed: (_busy || _selectedPost == null) ? null : _openEdit,
              child: const Text('Open Edit Screen'),
            ),
            ElevatedButton(
              onPressed: (_busy || _selectedPost == null) ? null : _removeImages,
              child: const Text('Remove Images'),
            ),
          ]),
        ),
        // Post selector + update fields
        if (_posts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                if (post != null) {
                  setState(() {
                    _selectedPost = post;
                    _titleController.text = post.title;
                    _bodyController.text = post.body ?? '';
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'New title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'New body',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy ? null : _updatePost,
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ],
        const Divider(),
        Expanded(
          child: ListView(
            children: _log
                .map((l) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: SelectableText(
                        l,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }
}