import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhotoPicker extends StatefulWidget {
  final String? currentAvatarUrl;
  final bool isSaving;
  final void Function((Uint8List bytes, String extension)? pick) onAvatarChanged; // null = removed

  const ProfilePhotoPicker({
    super.key,
    this.currentAvatarUrl,
    required this.isSaving,
    required this.onAvatarChanged,
  });

  @override
  State<ProfilePhotoPicker> createState() => _ProfilePhotoPickerState();
}

class _ProfilePhotoPickerState extends State<ProfilePhotoPicker> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _busy = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
      setState(() => _busy = false);
      widget.onAvatarChanged((bytes, ext));
    } catch (e) {
      setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      widget.onAvatarChanged(null);
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = widget.currentAvatarUrl != null;
    return Column(
      children: [
        GestureDetector(
          onTap: widget.isSaving ? null : _pick,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: hasAvatar
                  ? DecorationImage(
                      image: NetworkImage(widget.currentAvatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: !hasAvatar
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: (widget.isSaving || _busy) ? null : _pick,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.image),
              label: Text(hasAvatar ? 'Replace Avatar' : 'Pick Avatar'),
            ),
            if (hasAvatar) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: (widget.isSaving || _busy) ? null : _remove,
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}