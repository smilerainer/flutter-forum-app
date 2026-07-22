import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:forum_app/core/data/storage_service.dart';
import 'package:forum_app/core/result.dart';
import 'package:image_picker/image_picker.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;
  String? lastPostId;
  String? lastCommentId;
  String? lastUploadPath;

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
        Wrap(spacing: 8, children: buttons(this)),
        const Divider(),
        Expanded(
          child: ListView(children: _log.map((l) => Padding(
            padding: const EdgeInsets.all(4),
            child: Text(l, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          )).toList()),
        ),
      ]),
    );
  }
}

Future<Result<String>> uploadTest() async {
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile == null) {
    return const Failure('No image selected.');
  }

  final Uint8List bytes = await pickedFile.readAsBytes();
  final storage = StorageService();
  return storage.uploadFile('debug', bytes, 'debug/images');
}


List<Widget> buttons(_DebugConsoleState s) => [
  ElevatedButton(
    onPressed: () => s.run('Upload', () async {
      final result = await uploadTest();
      return switch (result) {
        Success<String>(:final data) => data,
        Failure<String>(:final message) => throw Exception(message),
      };
    }),
    child: const Text('Upload Image')
    )
];