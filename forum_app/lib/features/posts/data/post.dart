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

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: json['id'] as String,
    title: json['title'] as String,
    body: json['body'] as String?,
    userId: json['user_id'] as String,
    images: (json['post_images'] as List<dynamic>?)
        ?.map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    author: json['profiles'] != null
        ? UserProfile.fromJson(json['profiles'] as Map<String, dynamic>)
        : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

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
