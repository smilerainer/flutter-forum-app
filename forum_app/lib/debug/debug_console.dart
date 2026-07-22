import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
        Wrap(spacing: 8, children: buttons(this)), // grows every phase
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

List<Widget> buttons(_DebugConsoleState s) => [
 
];