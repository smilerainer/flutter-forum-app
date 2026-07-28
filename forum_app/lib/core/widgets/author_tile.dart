import 'package:flutter/material.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class AuthorTile extends StatelessWidget {
  final UserProfile? author;
  final double avatarRadius;

  const AuthorTile({super.key, required this.author, this.avatarRadius = 16});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: author?.avatarUrl != null
              ? NetworkImage(author!.avatarUrl!)
              : null,
          child: author?.avatarUrl == null
              ? Icon(Icons.person, size: avatarRadius)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            author?.displayName ?? 'Unknown',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
