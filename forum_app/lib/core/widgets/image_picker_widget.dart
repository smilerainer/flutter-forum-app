import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickerImage {
  final Uint8List bytes;
  final String name;

  const PickerImage({required this.bytes, required this.name});

  String get extension => name.contains('.') ? name.split('.').last : 'png';
}

typedef OnImagesChanged = void Function(List<PickerImage> images);

class ImagePickerWidget extends StatefulWidget {
  final OnImagesChanged? onImagesChanged;
  final ImageSource source;

  const ImagePickerWidget({
    super.key,
    this.onImagesChanged,
    this.source = ImageSource.gallery,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final List<PickerImage> _images = [];
  final Set<int> _selected = {};
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  bool get _massMode => _selected.isNotEmpty;

  Future<void> _pick() async {
    setState(() => _busy = true);
    try {
      if (widget.source == ImageSource.camera) {
        final picked = await _picker.pickImage(source: ImageSource.camera);
        if (picked != null) {
          final bytes = await picked.readAsBytes();
          _addImage(PickerImage(bytes: bytes, name: picked.name));
        }
      } else {
        final picked = await _picker.pickMultiImage();
        if (picked.isNotEmpty) {
          for (final xFile in picked) {
            final bytes = await xFile.readAsBytes();
            _addImage(PickerImage(bytes: bytes, name: xFile.name));
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addImage(PickerImage image) {
    setState(() => _images.add(image));
    widget.onImagesChanged?.call(List.unmodifiable(_images));
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _removeSingle(int index) {
    setState(() => _images.removeAt(index));
    final shifted = <int>{};
    for (final i in _selected) {
      if (i < index) {
        shifted.add(i);
      } else if (i > index) {
        shifted.add(i - 1);
      }
    }
    _selected
      ..clear()
      ..addAll(shifted);
    widget.onImagesChanged?.call(List.unmodifiable(_images));
  }

  void _removeSelected() {
    final sorted = _selected.toList()..sort((a, b) => b.compareTo(a));
    for (final index in sorted) {
      _images.removeAt(index);
    }
    _selected.clear();
    widget.onImagesChanged?.call(List.unmodifiable(_images));
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selected.length == _images.length) {
        _selected.clear();
      } else {
        _selected.addAll(List.generate(_images.length, (i) => i));
      }
    });
  }

  void _showPreview(PickerImage image) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.memory(
                    image.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Icon(Icons.broken_image, size: 64, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    image.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _busy ? null : _pick,
          icon: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.image),
          label: Text(
            widget.source == ImageSource.camera
                ? 'Take Photo'
                : 'Pick Images from Gallery',
          ),
        ),
        if (_images.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final image = _images[index];
                final isSelected = _selected.contains(index);
                return GestureDetector(
                  onTap: () => _showPreview(image),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          image.bytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(
                            width: 100,
                            height: 100,
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: GestureDetector(
                          onTap: () => _toggleSelection(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.grey.shade600 : Colors.white54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? Icons.check : Icons.circle_outlined,
                              size: 20,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      if (!_massMode)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeSingle(index),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${_images.length} image${_images.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (_massMode) ...[
                TextButton(
                  onPressed: _toggleSelectAll,
                  child: Text(
                    _selected.length == _images.length ? 'Deselect All' : 'Select All',
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: _removeSelected,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text('Delete Selected (${_selected.length})'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}