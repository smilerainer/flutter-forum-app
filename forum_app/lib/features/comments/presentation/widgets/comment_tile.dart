import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/core/widgets/author_tile.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_image_grid.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onDelete;
  final Future<void> Function(String? newBody)? onEdit;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _isEditing = false;
  late TextEditingController _editController;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.comment.body);
  }

  @override
  void didUpdateWidget(CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment.id != widget.comment.id) {
      _editController.text = widget.comment.body ?? '';
    }
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  Future<void> _saveEdit() async {
    final newBody = _editController.text.trim();
    if (widget.onEdit != null) {
      await widget.onEdit!(newBody.isEmpty ? null : newBody);
    }
    if (mounted) setState(() => _isEditing = false);
  }

  void _cancelEdit() {
    setState(() {
      _editController.text = widget.comment.body ?? '';
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwn = currentUserId != null && widget.comment.userId == currentUserId;

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
                Expanded(
                  child: AuthorTile(
                    author: widget.comment.author,
                    avatarRadius: 14,
                  ),
                ),
                Text(
                  _timeAgo(widget.comment.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOwn) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit comment',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: theme.colorScheme.error),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete comment',
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ],
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _editController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 3,
                minLines: 1,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveEdit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ] else ...[
              if (widget.comment.body != null) ...[
                const SizedBox(height: 8),
                Text(widget.comment.body!, style: theme.textTheme.bodyMedium),
              ],
              if (widget.comment.images.isNotEmpty) ...[
                const SizedBox(height: 8),
                PostImageGrid(images: widget.comment.images, compact: true),
              ],
            ],
          ],
        ),
      ),
    );
  }
}