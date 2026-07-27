import 'package:flutter/material.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_editor.dart';

class PostEditScreen extends StatefulWidget {
  final Post post;

  const PostEditScreen({super.key, required this.post});

  @override
  State<PostEditScreen> createState() => _PostEditScreenState();
}

class _PostEditScreenState extends State<PostEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _postService = PostService();
  final _storageService = StorageService();

  bool _isSubmitting = false;
  PostImageEditorState _editorState = PostImageEditorState(
    existingImages: const [],
  );

  Post get _post => widget.post;

  @override
  void initState() {
    super.initState();
    _titleController.text = _post.title;
    _bodyController.text = _post.body ?? '';
    _editorState = PostImageEditorState(
      existingImages: _post.images,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final newTitle = _titleController.text.trim();
      final newBody = _bodyController.text.trim();
      final removedIds = _editorState.removedIds.toList();
      final newImages = _editorState.newImages;

      // 1. Delete Storage files for removed images
      if (removedIds.isNotEmpty) {
        final removedRefs = _post.images
            .where((img) => removedIds.contains(img.id))
            .toList();

        for (final ref in removedRefs) {
          await _storageService.deleteFile(path: ref.storagePath);
        }

        // 2. Remove post_images rows
        final removeResult = await _postService.removeImages(removedIds);
        if (removeResult is Failure<void>) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(removeResult.message)),
            );
          }
          return;
        }
      }

      // 3. Upload new images
      if (newImages.isNotEmpty) {
        final uploadResults = await _storageService.uploadFileBatch(
          newImages.map((img) => img.bytes).toList(),
          directory: 'post-images',
          extension: 'jpg',
        );

        final paths = <String>[];
        for (final result in uploadResults) {
          if (result is Success<String>) {
            paths.add(result.data);
          }
        }

        // 4. Attach new images to post
        if (paths.isNotEmpty) {
          final attachResult = await _postService.attachImages(_post.id, paths);
          if (attachResult is Failure<void>) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(attachResult.message)),
              );
            }
            return;
          }
        }
      }

      // 5. Update post title/body
      final updateResult = await _postService.updatePost(
        _post.id,
        newTitle,
        newBody.isEmpty ? null : newBody,
      );

      if (updateResult is Failure<void>) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(updateResult.message)),
          );
        }
        return;
      }

      // 6. Fetch refreshed post and pop back
      final refreshedResult = await _postService.getPost(_post.id);
      if (refreshedResult is Success<Post> && mounted) {
        Navigator.pop(context, refreshedResult.data);
      } else if (mounted) {
        // Fallback: pop with original post (update did succeed)
        Navigator.pop(context, _post);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Body (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                minLines: 3,
              ),
              const SizedBox(height: 24),
              PostImageEditor(
                existingImages: _post.images,
                onChanged: (state) {
                  setState(() => _editorState = state);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}