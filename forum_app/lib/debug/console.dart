import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
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

  String? lastUploadPath;
  List<String>? lastBatchPaths;

  Post? lastEditPost;
  PostImageEditorState? _editorState;
  int _editorGeneration = 0;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void log(String message) {
    setState(() => _log.insert(0, message));
  }

  void logStep(String message) {
    log('   • $message');
  }

  Future<void> run(String label, Future<String> Function() action) async {
    setState(() => _busy = true);
    log('▶ $label');
    try {
      final result = await action();
      log('✅ $label → $result');
    } catch (e) {
      log('❌ $label → $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _log.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  Future<String> _createFixture() async {
    final postService = PostService();
    final storageService = StorageService();

    final createResult = await postService.createPost('Edit Fixture', 'original body');
    if (createResult is Failure<String>) throw Exception(createResult.message);
    final postId = (createResult as Success<String>).data;
    logStep('Post created: $postId');

    final picked = await ImagePicker().pickMultiImage();
    if (picked.length != 2) {
      throw Exception('Pick exactly 2 images to proceed (picked ${picked.length})');
    }
    final bytesList = await Future.wait(picked.map((f) => f.readAsBytes()));

    final uploadResults = await storageService.uploadFileBatch(
      bytesList,
      directory: 'posts/$postId',
      extension: 'jpg',
    );
    final paths = <String>[];
    for (final r in uploadResults) {
      if (r is Failure<String>) throw Exception('Upload failed: ${r.message}');
      final path = (r as Success<String>).data;
      paths.add(path);
      logStep('Uploaded $path');
    }

    final attachResult = await postService.attachImages(postId, paths);
    if (attachResult is Failure<void>) throw Exception(attachResult.message);
    logStep('Attached ${paths.length} image(s)');

    final refreshed = await postService.getPost(postId);
    if (refreshed is Failure<Post>) throw Exception(refreshed.message);
    final post = (refreshed as Success<Post>).data;
    logStep('Refetched from server: ${post.images.length} image(s)');

    setState(() {
      lastEditPost = post;
      _editorState = null;
      _editorGeneration++;
      _titleController.text = post.title;
      _bodyController.text = post.body ?? '';
    });

    return 'postId=$postId, images=${post.images.length}';
  }

  Future<String> _submitEdit() async {
    final post = lastEditPost!;
    final postService = PostService();
    final storageService = StorageService();

    final removedIds = _editorState?.removedIds ?? <String>{};
    final newImages = _editorState?.newImages ?? [];
    final toRemove = post.images.where((img) => removedIds.contains(img.id)).toList();

    if (toRemove.isNotEmpty) {
      for (final img in toRemove) {
        final result = await storageService.deleteFile(path: img.storagePath);
        if (result is Failure<void>) {
          throw Exception('Storage delete failed for ${img.storagePath}: ${result.message}');
        }
        logStep('Deleted storage file ${img.storagePath}');
      }
      final removeResult = await postService.removeImages(toRemove.map((e) => e.id).toList());
      if (removeResult is Failure<void>) throw Exception(removeResult.message);
      logStep('Removed ${toRemove.length} post_images row(s)');
    }

    if (newImages.isNotEmpty) {
      final uploadResults = await storageService.uploadFileBatch(
        newImages.map((e) => e.bytes).toList(),
        directory: 'posts/${post.id}',
        extension: 'jpg',
      );
      final paths = <String>[];
      for (final r in uploadResults) {
        if (r is Failure<String>) throw Exception('Upload failed: ${r.message}');
        final path = (r as Success<String>).data;
        paths.add(path);
        logStep('Uploaded $path');
      }
      final attachResult = await postService.attachImages(post.id, paths);
      if (attachResult is Failure<void>) throw Exception(attachResult.message);
      logStep('Attached ${paths.length} new image(s)');
    }

    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final updateResult = await postService.updatePost(post.id, title, body.isEmpty ? null : body);
    if (updateResult is Failure<void>) throw Exception(updateResult.message);
    logStep('Post row updated');

    final refreshed = await postService.getPost(post.id);
    if (refreshed is Failure<Post>) throw Exception(refreshed.message);
    final updated = (refreshed as Success<Post>).data;
    logStep('Refetched from server: ${updated.images.length} image(s), title="${updated.title}"');

    setState(() {
      lastEditPost = updated;
      _editorState = null;
      _editorGeneration++;
      _titleController.text = updated.title;
      _bodyController.text = updated.body ?? '';
    });

    return 'title="${updated.title}", images=${updated.images.length}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: buttons(this)),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
            const Divider(),
            if (lastEditPost != null) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              PostImageEditor(
                key: ValueKey('${lastEditPost!.id}_$_editorGeneration'),
                existingImages: lastEditPost!.images,
                onChanged: (state) => setState(() => _editorState = state),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : () => run('Submit Edit (live)', _submitEdit),
                child: const Text('Submit Edit (live)'),
              ),
              const Divider(),
            ],
            Row(
              children: [
                const Text('LOG', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _log.isEmpty ? null : () => _copyAll(),
                  icon: const Icon(Icons.copy_all),
                  label: const Text('Copy All'),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _log.join('\n'),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Diff Images (pure logic)', () async {
                  const imgA = ImageRef(id: 'A', storagePath: 'a.jpg', position: 0);
                  const imgB = ImageRef(id: 'B', storagePath: 'b.jpg', position: 1);
                  const imgC = ImageRef(id: 'C', storagePath: 'c.jpg', position: 2);
                  const imgD = ImageRef(id: 'D', storagePath: 'd.jpg', position: 3);

                  final result = diffImages(
                    original: [imgA, imgB, imgC],
                    current: [imgA, imgC, imgD],
                  );

                  final removeOk = result.toRemove.length == 1 && result.toRemove.first == 'b.jpg';
                  final addOk = result.toAdd.length == 1 && result.toAdd.first.id == 'D';
                  if (!removeOk || !addOk) {
                    throw Exception(
                      'Unexpected diff: toRemove=${result.toRemove}, toAdd=${result.toAdd.map((e) => e.id).toList()}',
                    );
                  }

                  return 'toRemove=${result.toRemove}, toAdd=${result.toAdd.map((e) => e.id).toList()}';
                }),
        child: const Text('Diff Images (pure logic)'),
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Create New Edit Fixture (2 images)', s._createFixture),
        child: const Text('Create New Edit Fixture (2 images)'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s.lastEditPost == null)
            ? null
            : () => s.run('Verify Post State From Server', () async {
                  final postService = PostService();
                  final refreshed = await postService.getPost(s.lastEditPost!.id);
                  if (refreshed is Failure<Post>) throw Exception(refreshed.message);
                  final post = (refreshed as Success<Post>).data;
                  final images = post.images
                      .map((e) => '${e.id}@${e.storagePath}(pos ${e.position})')
                      .join(', ');
                  return 'title="${post.title}", body="${post.body}", images=[$images]';
                }),
        child: const Text('Verify Post State From Server'),
      ),
    ];