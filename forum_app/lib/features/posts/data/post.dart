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
  final int commentCount;
  final String? latestCommentBody;
  final String? latestCommentAuthorName;
  final String? latestCommentAvatarUrl;
  final List<ImageRef> latestCommentImages;

  const Post({
    required this.id,
    required this.title,
    this.body,
    required this.userId,
    required this.images,
    this.author,
    required this.createdAt,
    required this.updatedAt,
    this.commentCount = 0,
    this.latestCommentBody,
    this.latestCommentAuthorName,
    this.latestCommentAvatarUrl,
    this.latestCommentImages = const [],
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
    final comments = json['comments'] as List<dynamic>?;
    final latestComment = comments?.firstOrNull as Map<String, dynamic>?;
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
      commentCount: comments?.length ?? 0,
      latestCommentBody: latestComment?['body'] as String?,
      latestCommentAuthorName: _firstNestedField(json['comments'], 'profiles', 'display_name'),
      latestCommentAvatarUrl: _firstNestedField(json['comments'], 'profiles', 'avatar_url'),
      latestCommentImages: (latestComment?['comment_images'] as List<dynamic>?)
          ?.map((e) => ImageRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  static String? _firstNestedField(List<dynamic>? list, String parent, String key) {
    final first = list?.firstOrNull as Map<String, dynamic>?;
    final parentMap = first?[parent] as Map<String, dynamic>?;
    return parentMap?[key] as String?;
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
    'comments': latestCommentBody != null
        ? [
            {
              'body': latestCommentBody,
              'profiles': latestCommentAuthorName != null ? {
                'display_name': latestCommentAuthorName,
                'avatar_url': latestCommentAvatarUrl,
              } : null,
              'comment_images': latestCommentImages.map((e) => e.toJson()).toList(),
            }
          ]
        : [],
  };
}
