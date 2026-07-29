import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';

class PostImageEditorState {
  final List<ImageRef> existingImages;
  final Set<String> removedIds;
  final List<PickerImage> newImages;

  const PostImageEditorState({
    required this.existingImages,
    this.removedIds = const {},
    this.newImages = const [],
  });
}

typedef OnPostImageEditorChanged = void Function(PostImageEditorState state);

class PostImageEditor extends StatefulWidget {
  final List<ImageRef> existingImages;
  final OnPostImageEditorChanged? onChanged;

  const PostImageEditor({
    super.key,
    this.existingImages = const [],
    this.onChanged,
  });

  @override
  State<PostImageEditor> createState() => _PostImageEditorState();
}

class _PostImageEditorState extends State<PostImageEditor> {
  final Set<String> _removedIds = {};
  final List<PickerImage> _newImages = [];
  final StorageService _storage = StorageService();

  void _emit() {
    widget.onChanged?.call(PostImageEditorState(
      existingImages: widget.existingImages,
      removedIds: Set.unmodifiable(_removedIds),
      newImages: List.unmodifiable(_newImages),
    ));
  }

  void _toggleRemove(String id) {
    setState(() {
      if (_removedIds.contains(id)) {
        _removedIds.remove(id);
      } else {
        _removedIds.add(id);
      }
    });
    _emit();
  }

  void _onNewImagesChanged(List<PickerImage> images) {
    setState(() {
      _newImages
        ..clear()
        ..addAll(images);
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.existingImages.isNotEmpty) ...[
          Text(
            'Existing Images',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.existingImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final image = widget.existingImages[index];
                final isRemoved = _removedIds.contains(image.id);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _storage.getPublicUrl(image.storagePath),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 100,
                          height: 100,
                          child: Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _toggleRemove(image.id),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isRemoved ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRemoved ? Icons.restore : Icons.close,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (isRemoved)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text(
                              'Removed',
                              style: TextStyle(color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'pos ${image.position}',
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (_removedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_removedIds.length} image(s) marked for removal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
        ],
        ImagePickerWidget(
          onImagesChanged: _onNewImagesChanged,
        ),
      ],
    );
  }
}