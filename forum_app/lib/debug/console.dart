import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/data/supabase_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/logic/post_form_view_model.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_editor.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;

  final List<Post> _posts = [];
  Post? _selectedPost;
  PostImageEditorState? _editorState;

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

  Future<void> _testSubmit() async {
    if (_selectedPost == null || _editorState == null) return;

    await run('Submit Edit', () async {
      final st = _editorState!;
      final post = _selectedPost!;
      final kept = st.existingImages
          .where((img) => !st.removedIds.contains(img.id))
          .toList();
      final current = [
        ...kept,
        ...st.newImages.map((p) => ImageRef(
          id: p.name,
          storagePath: p.name,
          position: kept.length,
        )),
      ];
      final diff = diffImages(original: post.images, current: current);
      final storage = StorageService();
      final db = SupabaseService.client;

      if (diff.toRemove.isNotEmpty) {
        final deleteResult = await storage.deleteFileBatch(diff.toRemove);
        for (final r in deleteResult) {
          if (r is Failure<void>) throw Exception(r.message);
        }
        await db.from('post_images').delete().eq('post_id', post.id);
      }

      if (diff.toAdd.isNotEmpty) {
        final bytes = st.newImages.map((p) => p.bytes).toList();
        final ext = st.newImages.first.extension;
        final uploadResults = await storage.uploadFileBatch(
          bytes,
          directory: 'post-images',
          extension: ext,
        );
        final paths = <String>[];
        for (final r in uploadResults) {
          switch (r) {
            case Success<String>(:final data):
              paths.add(data);
            case Failure<String>(:final message):
              throw Exception(message);
          }
        }
        final rows = paths.asMap().entries.map((e) => {
          'post_id': post.id,
          'storage_path': e.value,
          'position': kept.length + e.key,
        }).toList();
        await db.from('post_images').insert(rows);
      }

      await db.from('posts').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', post.id);

      return 'removed=${diff.toRemove.length}, added=${diff.toAdd.length}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorImages = _selectedPost?.images ?? <ImageRef>[];

    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          ElevatedButton(
            onPressed: _busy ? null : _fetchPosts,
            child: const Text('Fetch Posts'),
          ),
          ElevatedButton(
            onPressed: (_busy || _editorState == null) ? null : _testSubmit,
            child: const Text('Test Submit'),
          ),
        ]),
        const Divider(),
        if (_posts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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