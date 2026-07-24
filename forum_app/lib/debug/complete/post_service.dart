import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  String? lastUploadPath;
  List<String>? lastBatchPaths;

  String? _lastCreatedPostId;

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

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              hintText: 'Body (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ),
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
      ]),
    );
  }
}

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Fetch Posts', () async {
                  final service = PostService();
                  final result = await service.fetchPosts(limit: 10);
                  return switch (result) {
                    Success<dynamic>(:final data) =>
                      '${data.items.length} posts${data.items.isNotEmpty ? ', first: ${data.items.first.title}' : ''}',
                    Failure<dynamic>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Fetch Posts'),
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Create Post', () async {
                  final title = s._titleController.text.trim();
                  if (title.isEmpty) throw Exception('Enter a title first.');
                  final body = s._bodyController.text.trim();
                  final service = PostService();
                  final result = await service.createPost(title, body.isEmpty ? null : body);
                  return switch (result) {
                    Success<String>(:final data) => (s._lastCreatedPostId = data),
                    Failure<String>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Create Post'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastCreatedPostId == null)
            ? null
            : () => s.run('Attach Images', () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  if (picked.isEmpty) throw Exception('No images selected.');
                  if (picked.length > 5) throw Exception('Max 5 images.');

                  final storage = StorageService();
                  final paths = <String>[];
                  for (final f in picked) {
                    final bytes = await f.readAsBytes();
                    final ext = f.name.contains('.') ? f.name.split('.').last : 'png';
                    final uploadResult = await storage.uploadFile(bytes, directory: 'debug', extension: ext);
                    if (uploadResult is Success<String>) {
                      paths.add(uploadResult.data);
                    } else if (uploadResult is Failure<String>) {
                      throw Exception('Upload failed: ${uploadResult.message}');
                    }
                  }

                  final service = PostService();
                  final attachResult = await service.attachImages(s._lastCreatedPostId!, paths);
                  return switch (attachResult) {
                    Success<void> _ => '${paths.length} images attached',
                    Failure<void>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Attach Images to Last Post'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastCreatedPostId == null)
            ? null
            : () => s.run('Update Last Post', () async {
                  final title = s._titleController.text.trim();
                  if (title.isEmpty) throw Exception('Enter a title first.');
                  final body = s._bodyController.text.trim();
                  final service = PostService();
                  final result = await service.updatePost(
                    s._lastCreatedPostId!,
                    title,
                    body.isEmpty ? null : body,
                  );
                  return switch (result) {
                    Success<void> _ => 'Post ${s._lastCreatedPostId} updated',
                    Failure<void>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Update Last Post'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastCreatedPostId == null)
            ? null
            : () => s.run('Delete Last Created', () async {
                  final service = PostService();
                  final result = await service.deletePost(s._lastCreatedPostId!);
                  return switch (result) {
                    Success<void> _ => () {
                        final id = s._lastCreatedPostId;
                        s._lastCreatedPostId = null;
                        return 'Post $id deleted';
                      }(),
                    Failure<void>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Delete Last Created'),
      ),
    ];