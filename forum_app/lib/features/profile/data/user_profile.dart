class UserProfile {
    final String id;
    final String? displayName;
    final String? avatarUrl;

    final DateTime createdAt;
    final DateTime? updatedAt;

    const UserProfile ({
      required this.id,
      this.displayName,
      this.avatarUrl,

      required this.createdAt,
      this.updatedAt,
    });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawCreatedAt = json['created_at'];
    if (rawId == null || rawCreatedAt == null) return _empty();
    return UserProfile(
      id: rawId as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,

      createdAt: DateTime.parse(rawCreatedAt as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
  static UserProfile _empty() => UserProfile(
    id: '',
    displayName: null,
    avatarUrl: null,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: null,
  );
    Map<String, dynamic> toJson() => {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,

      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }