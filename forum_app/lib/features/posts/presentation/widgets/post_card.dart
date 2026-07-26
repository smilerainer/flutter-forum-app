import 'package:flutter/material.dart';
import 'package:forum_app/features/posts/data/post.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(post.id, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (post.body != null) Text(post.body!),
            if (post.author != null) SelectableText(post.author!.displayName ?? '(no displayName)'),
            PostImageGrid(images: post.images),
          ],
        ),
      ),
    );
  }
}