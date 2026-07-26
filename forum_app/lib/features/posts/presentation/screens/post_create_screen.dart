import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';
import 'package:forum_app/features/posts/data/post_service.dart';

class PostCreateScreen extends StatefulWidget {
  const PostCreateScreen({super.key});

  @override
  State<PostCreateScreen> createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _postService = PostService();
  final _storageService = StorageService();

  List<PickerImage> _pickedImages = [];
  bool _isSubmitting = false;

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
      // 1. Create the post
      final createResult = await _postService.createPost(
        _titleController.text.trim(),
        _bodyController.text.trim().isEmpty
            ? null
            : _bodyController.text.trim(),
      );

      if (createResult is Failure<String>) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(createResult.message)),
          );
        }
        return;
      }

      final postId = (createResult as Success<String>).data;

      // 2. Upload images if any
      if (_pickedImages.isNotEmpty) {
        final uploadResults = await _storageService.uploadFileBatch(
          _pickedImages.map((img) => img.bytes).toList(),
          directory: 'post-images',
          extension: 'jpg',
        );

        final paths = <String>[];
        for (final result in uploadResults) {
          if (result is Success<String>) {
            paths.add(result.data);
          }
        }

        // 3. Attach images to post
        if (paths.isNotEmpty) {
          await _postService.attachImages(postId, paths);
        }
      }

      if (mounted) {
        context.go('/posts');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
              Text(
                'Images',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ImagePickerWidget(
                onImagesChanged: (images) {
                  setState(() => _pickedImages = images);
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}