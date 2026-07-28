import 'package:flutter/material.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';
import 'package:forum_app/features/posts/presentation/widgets/comment_preview_card.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;

  const PostCard({super.key, required this.post, this.onTap});

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: post.author?.avatarUrl != null
                        ? NetworkImage(post.author!.avatarUrl!)
                        : null,
                    child: post.author?.avatarUrl == null
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.author?.displayName ?? 'Unknown',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _timeAgo(post.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (post.body != null && post.body!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  post.body!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
          if (post.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            PostImageGrid(images: post.images, compact: true),
          ],
          if (post.commentCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount} comment${post.commentCount == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (post.latestCommentBody != null || post.latestCommentImages.isNotEmpty)
              CommentPreviewCard(
                authorName: post.latestCommentAuthorName ?? 'Unknown',
                body: post.latestCommentBody,
                images: post.latestCommentImages,
              ),
          ],
            ],
          ),
        ),
      ),
    );
  }
}
