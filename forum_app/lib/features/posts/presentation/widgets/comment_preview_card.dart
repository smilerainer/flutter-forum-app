import 'package:flutter/material.dart';
import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/core/data/storage_service.dart';

class CommentPreviewCard extends StatelessWidget {
  final String authorName;
  final String? avatarUrl;
  final String? body;
  final List<ImageRef> images;

  const CommentPreviewCard({
    super.key,
    required this.authorName,
    this.avatarUrl,
    this.body,
    this.images = const [],
  });

  Widget _buildAvatar() {
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 10,
      backgroundImage: hasUrl ? NetworkImage(avatarUrl!) : null,
      child: hasUrl ? null : Text(authorName[0].toUpperCase()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (body == null && images.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAvatar(),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (body != null && body!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  body!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (images.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildImageThumbnails(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageThumbnails(BuildContext context) {
    final storage = StorageService();
    if (images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 4),
        itemBuilder: (_, index) {
          final image = images[index];
          final url = storage.getPublicUrl(image.storagePath);
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              url,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 60,
                height: 60,
                child: Icon(Icons.broken_image, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}