import 'package:flutter/material.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: comment.author?.avatarUrl != null
                      ? NetworkImage(comment.author!.avatarUrl!)
                      : null,
                  child: comment.author?.avatarUrl == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    comment.author?.displayName ?? 'Unknown',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _timeAgo(comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (comment.body != null) ...[
              const SizedBox(height: 8),
              Text(
                comment.body!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (comment.images.isNotEmpty) ...[
              const SizedBox(height: 8),
              PostImageGrid(images: comment.images),
            ],
          ],
        ),
      ),
    );
  }
}