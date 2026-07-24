import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/comments/data/comment_service.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;
  final TextEditingController _uuidController = TextEditingController();

  String? _lastPostUuid;
  String? _lastCreatedCommentId;

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
    _uuidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: buttons(this, context),
            ),
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

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s, BuildContext context) => [
      SizedBox(
        width: 400,
        child: TextField(
          controller: s._uuidController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Get Post', () async {
                  final uuid = s._uuidController.text.trim();
                  if (uuid.isEmpty) throw Exception('Enter a UUID first.');
                  final result = await PostService().getPost(uuid);
                  return switch (result) {
                    Success<Post>(:final data) => () {
                      s._lastPostUuid = uuid;
                      return 'Post: ${data.title}, images: ${data.images.length}';
                    }(),
                    Failure<Post>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Get Post'),
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Fetch Comments', () async {
                  final postId = s._uuidController.text.trim();
                  if (postId.isEmpty) throw Exception('Enter a UUID first.');
                  final result = await CommentService().fetchComments(postId);
                  return switch (result) {
                    Success<dynamic>(:final data) => () {
                      s._lastPostUuid = postId;
                      if (data.items.isNotEmpty) {
                        s._lastCreatedCommentId = data.items.last.id;
                      }
                      return '${data.items.length} comments${data.items.isNotEmpty ? ', last: ${data.items.last.body}' : ''}';
                    }(),
                    Failure<dynamic>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Fetch Comments'),
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Create Comment', () async {
                  final commentBody = s._uuidController.text.trim();
                  final postId = s._lastPostUuid;
                  if (postId == null) throw Exception('Fetch a post first to cache its UUID.');
                  if (commentBody.isEmpty) throw Exception('Enter a comment body in the text field.');
                  final result = await CommentService().createComment(commentBody, postId);
                  return switch (result) {
                    Success<String>(:final data) =>
                      (s._lastCreatedCommentId = data),
                    Failure<String>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Create Comment'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastCreatedCommentId == null)
            ? null
            : () => s.run('Attach Images to Comment', () async {
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

                  final result = await CommentService().attachImages(s._lastCreatedCommentId!, paths);
                  return switch (result) {
                    Success<void> _ => '${paths.length} images attached',
                    Failure<void>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Attach Images to Comment'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastCreatedCommentId == null)
            ? null
            : () => s.run('List Comment Image URLs', () async {
                  final postId = s._lastPostUuid;
                  if (postId == null) throw Exception('No cached post UUID. Fetch a post first.');
                  final result = await CommentService().fetchComments(postId);
                  final comments = switch (result) {
                    Success<dynamic>(:final data) => data.items,
                    Failure<dynamic>(:final message) => throw Exception(message),
                  };

                  Comment? comment;
                  for (final c in comments) {
                    if (c.id == s._lastCreatedCommentId) {
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
        onPressed: (s._busy || s._lastCreatedCommentId == null)
            ? null
            : () => s.run('Delete Last Comment', () async {
                  final result = await CommentService().deleteComment(s._lastCreatedCommentId!);
                  return switch (result) {
                    Success<void> _ => () {
                        final id = s._lastCreatedCommentId;
                        s._lastCreatedCommentId = null;
                        return 'Comment $id deleted';
                      }(),
                    Failure<void>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Delete Last Comment'),
      ),
    ];