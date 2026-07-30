import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';
import 'package:forum_app/features/comments/data/comment_service.dart';
import 'package:forum_app/features/comments/logic/comment_view_model.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_input.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_tile.dart';

class CommentSection extends StatefulWidget {
  final String postId;

  const CommentSection({super.key, required this.postId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _PickedImage {
  final XFile file;
  final Uint8List bytes;
  const _PickedImage(this.file, this.bytes);
}

class _CommentSectionState extends State<CommentSection> {
  late final CommentViewModel _viewModel;
  final ImagePicker _picker = ImagePicker();
  List<_PickedImage> _pickedImages = [];

  @override
  void initState() {
    super.initState();
    _viewModel = CommentViewModel(
      widget.postId,
      CommentService(),
      storageService: StorageService(),
    );
    _viewModel.loadComments();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      final loaded = <_PickedImage>[];
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        loaded.add(_PickedImage(x, bytes));
      }
      setState(() => _pickedImages.addAll(loaded));
    }
  }

  Future<void> _onSubmit(String body) async {
    await _viewModel.addComment(
      body,
      _pickedImages.map((p) => p.file).toList(),
    );
    if (mounted && _viewModel.error == null) {
      setState(() => _pickedImages = []);
      _viewModel.loadComments();
    }
  }

  Widget _buildImagePreviews() {
    if (_pickedImages.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _pickedImages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final picked = _pickedImages[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  picked.bytes,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 80,
                    height: 80,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _pickedImages.removeAt(index));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    if (!isSignedIn) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Sign in to leave a comment',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImagePreviews(),
          if (_pickedImages.isNotEmpty) const SizedBox(height: 8),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.image), onPressed: _pickImages),
              Expanded(
                child: CommentInput(
                  onSubmit: _onSubmit,
                  imagesCount: _pickedImages.length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_viewModel.error != null && _viewModel.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: ${_viewModel.error}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _viewModel.loadComments(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Comments',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            if (_viewModel.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _viewModel.items.length,
                itemBuilder: (_, index) {
                  final comment = _viewModel.items[index];
                  return CommentTile(
                    comment: comment,
                    onDelete: () async {
                      await _viewModel.deleteComment(comment.id);
                      _viewModel.loadComments();
                    },
                    onEdit:
                        (
                          newBody, {
                          Set<String> removedIds = const {},
                          List<PickerImage> newImages = const [],
                        }) async {
                          await _viewModel.editComment(
                            comment.id,
                            newBody,
                            removedIds: removedIds,
                            newImages: newImages,
                          );
                          _viewModel.loadComments();
                        },
                  );
                },
              ),
            const Divider(height: 1),
            _buildCommentInput(),
          ],
        );
      },
    );
  }
}
