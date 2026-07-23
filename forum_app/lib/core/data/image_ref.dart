class ImageRef {
  final String id;
  final String storagePath;
  final int position;

  const ImageRef({
    required this.id,
    required this.storagePath,
    required this.position,
  });

  factory ImageRef.fromJson(Map<String, dynamic> json) => ImageRef(
        id: json['id'] as String,
        storagePath: json['storage_path'] as String,
        position: json['position'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'storage_path': storagePath,
        'position': position,
      };
}
