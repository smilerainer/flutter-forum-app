import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/widgets/image_preview_dialog.dart';

class PostImageGrid extends StatelessWidget {
  final List<ImageRef> images;
  final bool compact;
  final StorageService? storageService;

  const PostImageGrid({
    super.key,
    required this.images,
    this.compact = false,
    this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final sortedImages = List<ImageRef>.of(images)..sort((a, b) => a.position.compareTo(b.position));

    final storage = storageService ?? StorageService();
    
    if (compact) {
      return _buildCompact(context, sortedImages, storage);
    }
    return _buildGrid(context, sortedImages, storage);
  }

  Widget _buildGrid(BuildContext context, List<ImageRef> images, StorageService storage) {
    
    if (images.length == 1) {
      final image = images.first;
      final url = storage.getPublicUrl(image.storagePath);
      return GestureDetector(
        onTap: () => showImagePreview(context, url),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (context, event, stackTrace) => const Icon(Icons.broken_image),
          ),
        ),
      );
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        final url = storage.getPublicUrl(image.storagePath);
        return GestureDetector(
          onTap: () => showImagePreview(context, url),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          ),
        );
      },
    );
  }

  Widget _buildCompact(BuildContext context, List<ImageRef> images, StorageService storage) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, index) {
          final image = images[index];
          final url = storage.getPublicUrl(image.storagePath);
          return GestureDetector(
            onTap: () => showImagePreview(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                url,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, event, stackTrace) => const SizedBox(
                  width: 80,
                  height: 80,
                  child: Center(child: Icon(Icons.broken_image)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}