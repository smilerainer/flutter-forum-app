class UserProfile {
    final String id;
    final String display_name;
    final String? avatar_url;

    final DateTime created_at;
    final DateTime? updated_at;

    const UserProfile ({
      required this.id,
      required this.display_name,
      required this.avatar_url,

      required this.created_at,
      required this.updated_at,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      display_name: json['display_name'] as String,
      avatar_url: json['avatar_url'] as String,

      created_at: json['created_at'] as DateTime,
      updated_at: json['updated_at'] as DateTime,
    );
    Map<String, dynamic> toJson() => {
      'id': id,
      'display_name': display_name,
      'avatar_url': avatar_url,

      'created_at': created_at,
      'updated_at': updated_at,
    };
  }