import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_editor.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  // ignore: unused_field
  bool _busy = false;

  String? lastUploadPath;
  List<String>? lastBatchPaths;
  PostImageEditorState? _editorState;

  final List<Post> _posts = [];
  Post? _selectedPost;

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
      final service = PostService();
      final result = await service.fetchPosts(limit: 5);
      return switch (result) {
        Success<dynamic>(:final data) => () {
          final fetched = data.items as List<Post>;
          setState(() {
            _posts
              ..clear()
              ..addAll(fetched);
            _selectedPost = _posts.isNotEmpty ? _posts.first : null;
          });
          return '${fetched.length} posts loaded';
        }(),
        Failure<dynamic>(:final message) => throw Exception(message),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorImages = _selectedPost?.images ?? <ImageRef>[];

    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: buttons(this)),
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
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_posts.isNotEmpty)
                DropdownButton<Post>(
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
              const SizedBox(height: 8),
              PostImageEditor(
                key: ValueKey(_selectedPost?.id),
                existingImages: editorImages,
                onChanged: (state) {
                  _editorState = state;
                },
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy ? null : () => s._fetchPosts(),
        child: const Text('Fetch Posts'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._editorState == null)
            ? null
            : () => s.run('Editor State', () async {
                  final st = s._editorState!;
                  return 'existing=${st.existingImages.length}, '
                      'removedIds=${st.removedIds.length}, '
                      'newImages=${st.newImages.length}';
                }),
        child: const Text('Log Editor State'),
      ),
    ];