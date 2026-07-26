import 'package:flutter/material.dart';
import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  // ignore: unused_field
  bool _busy = false;
  final List<PickerImage> _pickedImages = [];

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

  Future<void> _uploadSelected() async {
    if (_pickedImages.isEmpty) return;

    final images = List<PickerImage>.from(_pickedImages);
    final bytes = images.map((i) => i.bytes).toList();
    final ext = images.first.extension;

    await run('Upload ${images.length} image(s)', () async {
      final storage = StorageService();
      final results = await storage.uploadFileBatch(
        bytes,
        directory: 'debug',
        extension: ext,
      );

      final paths = <String>[];
      for (final r in results) {
        switch (r) {
          case Success<String>(:final data):
            paths.add(data);
          case Failure<String>(:final message):
            throw Exception(message);
        }
      }
      lastBatchPaths = paths;
      return paths.join(', ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: buttons(this)),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ImagePickerWidget(
            onImagesChanged: (images) {
              setState(() => _pickedImages
                ..clear()
                ..addAll(images));
            },
          ),
        ),
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

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: (s._busy || s._pickedImages.isEmpty)
            ? null
            : () => s._uploadSelected(),
        child: const Text('Upload Selected Images'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s.lastBatchPaths == null || s.lastBatchPaths!.isEmpty)
            ? null
            : () => s.run('Get Public URL (first)', () async {
                  final storage = StorageService();
                  return storage.getPublicUrl(s.lastBatchPaths!.first);
                }),
        child: const Text('Get Public URL'),
      ),
    ];