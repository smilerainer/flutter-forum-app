import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class Comment {
  final String id;
  final String body;
  final String postId;
  final String userId;
  final List<ImageRef> images;
  final UserProfile? author;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.body,
    required this.postId,
    required this.userId,
    required this.images,
    this.author,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final body = json['body'] as String?;
    final postId = json['post_id'] as String?;
    final userId = json['user_id'] as String?;
    final createdAtStr = json['created_at'] as String?;
    if (id == null ||
        body == null ||
        postId == null ||
        userId == null ||
        createdAtStr == null) {
      throw const FormatException('Missing required comment fields');
    }
    return Comment(
      id: id,
      body: body,
      postId: postId,
      userId: userId,
      images: (json['comment_images'] as List<dynamic>?)
          ?.map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      author: json['profiles'] != null
          ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'body': body,
    'post_id': postId,
    'user_id': userId,
    'comment_images': images.map((e) => e.toJson()).toList(),
    'profiles': author?.toJson(),
    'created_at': createdAt.toIso8601String(),
  };
}