import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/widgets/image_preview_dialog.dart';

class PostImageGrid extends StatelessWidget {
  final List<ImageRef> images;
  final bool compact;

  const PostImageGrid({
    super.key,
    required this.images,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    if (compact) {
      return _buildCompact(context);
    }
    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final storage = StorageService();
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

  Widget _buildCompact(BuildContext context) {
    final storage = StorageService();
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
                errorBuilder: (_, _, _) => const SizedBox(
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