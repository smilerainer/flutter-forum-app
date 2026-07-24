import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';

class StorageServicePanel extends StatefulWidget {
  final void Function(String label, Future<String> Function() action) onRun;
  final bool busy;

  const StorageServicePanel({super.key, required this.onRun, required this.busy});

  // Test keys — not visible in the UI
  static const uploadBtnKey = Key('storage_upload_btn');
  static const getUrlBtnKey = Key('storage_get_url_btn');
  static const deleteBtnKey = Key('storage_delete_btn');
  static const batchUploadBtnKey = Key('storage_batch_upload_btn');
  static const batchDeleteBtnKey = Key('storage_batch_delete_btn');

  @override
  State<StorageServicePanel> createState() => _StorageServicePanelState();
}

class _StorageServicePanelState extends State<StorageServicePanel>
    with AutomaticKeepAliveClientMixin {
  String? lastUploadPath;
  List<String>? lastBatchPaths;

  @override
  bool get wantKeepAlive => true;

  List<Widget> get buttons => [
        ElevatedButton(
          key: StorageServicePanel.uploadBtnKey,
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Upload', () async {
                    final storage = StorageService();
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked == null) throw Exception('No image selected.');

                    final bytes = await picked.readAsBytes();
                    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
                    final result = await storage.uploadFile(bytes, directory: 'debug', extension: ext);

                    return switch (result) {
                      Success<String>(:final data) => (lastUploadPath = data),
                      Failure<String>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Test: Upload Image'),
        ),
        ElevatedButton(
          key: StorageServicePanel.getUrlBtnKey,
          onPressed: (widget.busy || lastUploadPath == null)
              ? null
              : () => widget.onRun('Get Public URL', () async {
                    final storage = StorageService();
                    return storage.getPublicUrl(lastUploadPath!);
                  }),
          child: const Text('Test: Get Public URL'),
        ),
        ElevatedButton(
          key: StorageServicePanel.deleteBtnKey,
          onPressed: (widget.busy || lastUploadPath == null)
              ? null
              : () => widget.onRun('Delete', () async {
                    final relativePath = lastUploadPath!.replaceFirst('images/', '');
                    final storage = StorageService();
                    final result = await storage.deleteFile(path: relativePath);
                    return switch (result) {
                      Success<void> _ => lastUploadPath!,
                      Failure<void>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Test: Delete Recent'),
        ),
        ElevatedButton(
          key: StorageServicePanel.batchUploadBtnKey,
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Batch Upload', () async {
                    final storage = StorageService();
                    final picker = ImagePicker();
                    final picked = await picker.pickMultiImage();
                    if (picked.length != 3) {
                      throw Exception('Pick exactly 3 images (picked ${picked.length}).');
                    }

                    final byteList = <Uint8List>[
                      for (final f in picked) await f.readAsBytes(),
                    ];
                    final results = await storage.uploadFileBatch(byteList, directory: 'debug');

                    final failures = results.whereType<Failure<String>>().toList();
                    if (failures.isNotEmpty) {
                      throw Exception('${failures.length}/3 failed: ${failures.map((f) => f.message).join('; ')}');
                    }

                    final paths = results.cast<Success<String>>().map((r) => r.data).toList();
                    lastBatchPaths = paths;
                    return paths.join(', ');
                  }),
          child: const Text('Test: Batch Upload (3)'),
        ),
        ElevatedButton(
          key: StorageServicePanel.batchDeleteBtnKey,
          onPressed: (widget.busy || lastBatchPaths == null)
              ? null
              : () => widget.onRun('Batch Delete', () async {
                    final storage = StorageService();
                    final results = await storage.deleteFileBatch(lastBatchPaths!);

                    final failures = results.whereType<Failure<void>>().toList();
                    if (failures.isNotEmpty) {
                      throw Exception(
                          '${failures.length}/${results.length} failed: ${failures.map((f) => f.message).join('; ')}');
                    }

                    final count = results.length;
                    lastBatchPaths = null;
                    return '$count files deleted';
                  }),
          child: const Text('Test: Batch Delete'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
    );
  }
}