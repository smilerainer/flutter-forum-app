import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class Post {
  final String id;
  final String title;
  final String? body;
  final String userId;
  final List<ImageRef> images;
  final UserProfile? author;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.title,
    this.body,
    required this.userId,
    required this.images,
    this.author,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    final userId = json['user_id'] as String?;
    final createdAtStr = json['created_at'] as String?;
    final updatedAtStr = json['updated_at'] as String?;
    if (id == null ||
        title == null ||
        userId == null ||
        createdAtStr == null ||
        updatedAtStr == null) {
      throw const FormatException('Missing required post fields');
    }
    return Post(
      id: id,
      title: title,
      body: json['body'] as String?,
      userId: userId,
      images: (json['post_images'] as List<dynamic>?)
          ?.map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      author: json['profiles'] != null
          ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(createdAtStr),
      updatedAt: DateTime.parse(updatedAtStr),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'user_id': userId,
    'post_images': images.map((e) => e.toJson()).toList(),
    'profiles': author?.toJson(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
