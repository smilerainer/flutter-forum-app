import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;

  String? lastUploadPath;
  List<String>? lastBatchPaths;

  Future<void> run(String label, Future<String> Function() action) async {
    setState(() => _busy = true);
    try {
      final result = await action();
      setState(() => _log.insert(0, '✅ $label → $result'));
    } catch (e) {
      setState(() => _log.insert(0, '❌ $label → $e'));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: buttons(this)),
        const Divider(),
        Expanded(
          child: ListView(
            children: _log
                .map((l) => Padding(
                      padding: const EdgeInsets.all(4),
                      child: SelectableText(
                        l,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }
}

List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Upload', () async {
                  final storage = StorageService();
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked == null) throw Exception('No image selected.');

                  final bytes = await picked.readAsBytes();
                  final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
                  final result = await storage.uploadFile(bytes, directory: 'debug', extension: ext);

                  return switch (result) {
                    Success<String>(:final data) => (s.lastUploadPath = data),
                    Failure<String>(:final message) => throw Exception(message),
                  };
                }),
        child: const Text('Test: Upload Image'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s.lastUploadPath == null)
            ? null
            : () => s.run('Get Public URL', () async {
                  final storage = StorageService();
                  return storage.getPublicUrl(s.lastUploadPath!);
                }),
        child: const Text('Test: Get Public URL'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s.lastUploadPath == null) ? null : () => s.run(
          'Delete', () async {
          final relativePath = s.lastUploadPath!.replaceFirst('images/', '');
          final storage = StorageService();
          final result = await storage.deleteFile(path: relativePath);
          return switch (result) {
            Success<void> _ => s.lastUploadPath!,
            Failure<void>(:final message) => throw Exception(message),
          };
        }),
        child: const Text('Test: Delete Recent')
      ),
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Batch Upload', () async {
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
                  s.lastBatchPaths = paths;
                  return paths.join(', ');
                }),
        child: const Text('Test: Batch Upload (3)'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s.lastBatchPaths == null)
            ? null
            : () => s.run('Batch Delete', () async {
                  final storage = StorageService();
                  final results = await storage.deleteFileBatch(s.lastBatchPaths!);

                  final failures = results.whereType<Failure<void>>().toList();
                  if (failures.isNotEmpty) {
                    throw Exception(
                        '${failures.length}/${results.length} failed: ${failures.map((f) => f.message).join('; ')}');
                  }

                  final count = results.length;
                  s.lastBatchPaths = null;
                  return '$count files deleted';
                }),
        child: const Text('Test: Batch Delete'),
      ),
    ];