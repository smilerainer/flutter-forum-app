import 'package:flutter/material.dart';
import 'package:forum_app/core/data/storage_service.dart';

/// Shows a full-screen image preview with InteractiveViewer for pinch-to-zoom.
void showImagePreview(BuildContext context, String? url) {
  if (url == null) return;
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
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.white70,
                    ),
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
        ],
      ),
    ),
  );
}

/// Resolves storage path to a public URL via StorageService.
String? storageUrl(String? storagePath) {
  if (storagePath == null) return null;
  return StorageService().getPublicUrl(storagePath);
}
