import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';

class PostServicePanel extends StatefulWidget {
  final void Function(String label, Future<String> Function() action) onRun;
  final bool busy;

  const PostServicePanel({super.key, required this.onRun, required this.busy});

  // Test keys — not visible in the UI
  static const titleFieldKey = Key('post_title_field');
  static const bodyFieldKey = Key('post_body_field');
  static const postUuidFieldKey = Key('post_uuid_field');
  static const createBtnKey = Key('post_create_btn');
  static const fetchBtnKey = Key('post_fetch_btn');
  static const getPostBtnKey = Key('post_get_btn');
  static const updateBtnKey = Key('post_update_btn');
  static const attachImagesBtnKey = Key('post_attach_images_btn');
  static const deleteBtnKey = Key('post_delete_btn');

  @override
  State<PostServicePanel> createState() => _PostServicePanelState();
}

class _PostServicePanelState extends State<PostServicePanel>
    with AutomaticKeepAliveClientMixin {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _postUuidController = TextEditingController();
  String? _lastCreatedPostId;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _postUuidController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Widget> get buttons => [
        ElevatedButton(
          key: PostServicePanel.fetchBtnKey,
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Fetch Posts', () async {
                    final service = PostService();
                    final result = await service.fetchPosts(limit: 5);
                    return switch (result) {
                      Success<dynamic>(:final data) => data.items.map((p) =>
                        'id: ${p.id}, author: ${p.author?.displayName ?? '(anon)'}, title: ${p.title}',
                      ).join('\n'),
                      Failure<dynamic>(:final message) =>
                        throw Exception(message),
                    };
                  }),
          child: const Text('Fetch Posts'),
        ),
        ElevatedButton(
          key: PostServicePanel.getPostBtnKey,
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Get Post', () async {
                    final uuid = _postUuidController.text.trim();
                    if (uuid.isEmpty) throw Exception('Enter a UUID in the field.');
                    final service = PostService();
                    final result = await service.getPost(uuid);
                    return switch (result) {
                      Success<Post>(:final data) => () {
                        _lastCreatedPostId = uuid;
                        return 'id: ${data.id}, author: ${data.author?.displayName ?? '(anon)'}, title: ${data.title}';
                      }(),
                      Failure<Post>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Get Post'),
        ),
        ElevatedButton(
          key: PostServicePanel.createBtnKey,
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
          key: PostServicePanel.attachImagesBtnKey,
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
          key: PostServicePanel.updateBtnKey,
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
          key: PostServicePanel.deleteBtnKey,
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
            key: PostServicePanel.titleFieldKey,
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: 'Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: PostServicePanel.bodyFieldKey,
            controller: _bodyController,
            decoration: const InputDecoration(
              hintText: 'Body (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          TextField(
            key: PostServicePanel.postUuidFieldKey,
            controller: _postUuidController,
            decoration: const InputDecoration(
              hintText: 'Post UUID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }
}