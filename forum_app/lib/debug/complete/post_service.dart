import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';

class PostServicePanel extends StatefulWidget {
  final void Function(String label, Future<String> Function() action) onRun;
  final bool busy;

  const PostServicePanel({super.key, required this.onRun, required this.busy});

  @override
  State<PostServicePanel> createState() => _PostServicePanelState();
}

class _PostServicePanelState extends State<PostServicePanel>
    with AutomaticKeepAliveClientMixin {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _lastCreatedPostId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Widget> get buttons => [
        ElevatedButton(
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Fetch Posts', () async {
                    final service = PostService();
                    final result = await service.fetchPosts(limit: 10);
                    return switch (result) {
                      Success<dynamic>(:final data) =>
                        '${data.items.length} posts${data.items.isNotEmpty ? ', first: ${data.items.first.title}' : ''}',
                      Failure<dynamic>(:final message) =>
                        throw Exception(message),
                    };
                  }),
          child: const Text('Fetch Posts'),
        ),
        ElevatedButton(
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Create Post', () async {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) throw Exception('Enter a title first.');
                    final body = _bodyController.text.trim();
                    final service = PostService();
                    final result =
                        await service.createPost(title, body.isEmpty ? null : body);
                    return switch (result) {
                      Success<String>(:final data) => (_lastCreatedPostId = data),
                      Failure<String>(:final message) =>
                        throw Exception(message),
                    };
                  }),
          child: const Text('Create Post'),
        ),
        ElevatedButton(
          onPressed:
              (widget.busy || _lastCreatedPostId == null) ? null : () => widget.onRun('Attach Images', () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage();
                    if (picked.isEmpty) throw Exception('No images selected.');
                    if (picked.length > 5) throw Exception('Max 5 images.');

                    final storage = StorageService();
                    final paths = <String>[];
                    for (final f in picked) {
                      final bytes = await f.readAsBytes();
                      final ext = f.name.contains('.') ? f.name.split('.').last : 'png';
                      final uploadResult =
                          await storage.uploadFile(bytes, directory: 'debug', extension: ext);
                      if (uploadResult is Success<String>) {
                        paths.add(uploadResult.data);
                      } else if (uploadResult is Failure<String>) {
                        throw Exception('Upload failed: ${uploadResult.message}');
                      }
                    }

                    final service = PostService();
                    final attachResult =
                        await service.attachImages(_lastCreatedPostId!, paths);
                    return switch (attachResult) {
                      Success<void> _ => '${paths.length} images attached',
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Attach Images to Last Post'),
        ),
        ElevatedButton(
          onPressed:
              (widget.busy || _lastCreatedPostId == null) ? null : () => widget.onRun('Update Last Post', () async {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) throw Exception('Enter a title first.');
                    final body = _bodyController.text.trim();
                    final service = PostService();
                    final result = await service.updatePost(
                      _lastCreatedPostId!,
                      title,
                      body.isEmpty ? null : body,
                    );
                    return switch (result) {
                      Success<void> _ => 'Post $_lastCreatedPostId updated',
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Update Last Post'),
        ),
        ElevatedButton(
          onPressed:
              (widget.busy || _lastCreatedPostId == null) ? null : () => widget.onRun('Delete Last Created', () async {
                    final service = PostService();
                    final result = await service.deletePost(_lastCreatedPostId!);
                    return switch (result) {
                      Success<void> _ => () {
                          final id = _lastCreatedPostId;
                          _lastCreatedPostId = null;
                          return 'Post $id deleted';
                        }(),
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Delete Last Created'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bodyController,
            decoration: const InputDecoration(
              hintText: 'Body (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }
}