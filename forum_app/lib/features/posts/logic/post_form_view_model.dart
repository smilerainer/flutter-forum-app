import 'package:flutter/foundation.dart';
import 'package:forum_app/core/data/image_ref.dart';

({List<String> toRemove, List<ImageRef> toAdd}) diffImages({
  required List<ImageRef> original,
  required List<ImageRef> current,
}) {
  final originalIds = original.map((e) => e.id).toSet();
  final currentIds = current.map((e) => e.id).toSet();
  final toRemove = original
      .where((img) => !currentIds.contains(img.id))
      .map((e) => e.storagePath)
      .toList();
  final toAdd = current
      .where((img) => !originalIds.contains(img.id))
      .toList();
  return (toRemove: toRemove, toAdd: toAdd);
}

class PostFormViewModel extends ChangeNotifier {
  // ignore: prefer_final_fields
  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;
}