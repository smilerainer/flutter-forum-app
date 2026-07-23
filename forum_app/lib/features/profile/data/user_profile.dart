class UserProfile {
    final String id;
    final String displayName;
    final String? avatarUrl;

    final DateTime createdAt;
    final DateTime? updatedAt;

    const UserProfile ({
      required this.id,
      required this.displayName,
      required this.avatarUrl,

      required this.createdAt,
      required this.updatedAt,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String,

      createdAt: json['created_at'] as DateTime,
      updatedAt: json['updated_at'] as DateTime,
    );
    Map<String, dynamic> toJson() => {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,

      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }