class ImageRef {
  final String id;
  final String storagePath;
  final int position;

  const ImageRef({
    required this.id,
    required this.storagePath,
    required this.position,
  });

  factory ImageRef.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final storagePath = json['storage_path'] as String?;
    final position = json['position'] as int?;
    if (id == null || storagePath == null || position == null) {
      throw const FormatException('Missing required image fields');
    }
    return ImageRef(
      id: id,
      storagePath: storagePath,
      position: position,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'storage_path': storagePath,
    'position': position,
  };
}
