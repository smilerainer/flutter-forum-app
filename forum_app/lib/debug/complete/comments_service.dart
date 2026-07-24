import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/comments/data/comment_service.dart';

class CommentsServicePanel extends StatefulWidget {
  final void Function(String label, Future<String> Function() action) onRun;
  final bool busy;

  const CommentsServicePanel({super.key, required this.onRun, required this.busy});

  @override
  State<CommentsServicePanel> createState() => _CommentsServicePanelState();
}

class _CommentsServicePanelState extends State<CommentsServicePanel>
    with AutomaticKeepAliveClientMixin {
  final _uuidController = TextEditingController();
  String? _lastPostUuid;
  String? _lastCreatedCommentId;

  @override
  void dispose() {
    _uuidController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Widget> get buttons => [
        SizedBox(
          width: 400,
          child: TextField(
            controller: _uuidController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Get Post', () async {
                    final uuid = _uuidController.text.trim();
                    if (uuid.isEmpty) throw Exception('Enter a UUID first.');
                    final result = await PostService().getPost(uuid);
                    return switch (result) {
                      Success<Post>(:final data) => () {
                          _lastPostUuid = uuid;
                          return 'Post: ${data.title}, images: ${data.images.length}';
                        }(),
                      Failure<Post>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Get Post'),
        ),
        ElevatedButton(
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Fetch Comments', () async {
                    final postId = _uuidController.text.trim();
                    if (postId.isEmpty) throw Exception('Enter a UUID first.');
                    final result = await CommentService().fetchComments(postId);
                    return switch (result) {
                      Success<dynamic>(:final data) => () {
                          _lastPostUuid = postId;
                          if (data.items.isNotEmpty) {
                            _lastCreatedCommentId = data.items.last.id;
                          }
                          return '${data.items.length} comments${data.items.isNotEmpty ? ', last: ${data.items.last.body}' : ''}';
                        }(),
                      Failure<dynamic>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Fetch Comments'),
        ),
        ElevatedButton(
          onPressed: (widget.busy || _lastPostUuid == null)
              ? null
              : () => widget.onRun('Create Comment', () async {
                    final commentBody = _uuidController.text.trim();
                    final postId = _lastPostUuid;
                    if (postId == null) throw Exception('Fetch a post first to cache its UUID.');
                    if (commentBody.isEmpty) throw Exception('Enter a comment body in the text field.');
                    final result = await CommentService().createComment(commentBody, postId);
                    return switch (result) {
                      Success<String>(:final data) =>
                        (_lastCreatedCommentId = data),
                      Failure<String>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Create Comment'),
        ),
        ElevatedButton(
          onPressed: (widget.busy || _lastCreatedCommentId == null)
              ? null
              : () => widget.onRun('Attach Images to Comment', () async {
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

                    final result = await CommentService().attachImages(_lastCreatedCommentId!, paths);
                    return switch (result) {
                      Success<void> _ => '${paths.length} images attached',
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Attach Images to Comment'),
        ),
        ElevatedButton(
          onPressed: (widget.busy || _lastCreatedCommentId == null)
              ? null
              : () => widget.onRun('List Comment Image URLs', () async {
                    final postId = _lastPostUuid;
                    if (postId == null) throw Exception('No cached post UUID. Fetch a post first.');
                    final result = await CommentService().fetchComments(postId);
                    final comments = switch (result) {
                      Success<dynamic>(:final data) => data.items,
                      Failure<dynamic>(:final message) => throw Exception(message),
                    };

                    Comment? comment;
                    for (final c in comments) {
                      if (c.id == _lastCreatedCommentId) {
                        comment = c;
                        break;
                      }
                    }
                    if (comment == null) throw Exception('Comment not found in list.');

                    final urls = comment.images.map((img) => StorageService().getPublicUrl(img.storagePath)).toList();
                    return urls.isEmpty
                        ? 'No images on this comment'
                        : urls.map((u) => '\n$u').join('');
                  }),
          child: const Text('List Comment Image URLs'),
        ),
        ElevatedButton(
          onPressed: (widget.busy || _lastCreatedCommentId == null)
              ? null
              : () => widget.onRun('Delete Last Comment', () async {
                    final result = await CommentService().deleteComment(_lastCreatedCommentId!);
                    return switch (result) {
                      Success<void> _ => () {
                          final id = _lastCreatedCommentId;
                          _lastCreatedCommentId = null;
                          return 'Comment $id deleted';
                        }(),
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Delete Last Comment'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: buttons),
    );
  }
}