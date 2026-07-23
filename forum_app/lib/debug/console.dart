import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class DebugConsole extends StatefulWidget {
  const DebugConsole({super.key});
  @override
  State<DebugConsole> createState() => _DebugConsoleState();
}

class _DebugConsoleState extends State<DebugConsole> {
  final List<String> _log = [];
  bool _busy = false;
  final _textController = TextEditingController();
  String? _lastFetchedUid;

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
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Enter UID or name...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
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
            : () => s.run('Fetch Profile', () async {
                  final uid = s._textController.text.trim();
                  if (uid.isEmpty) throw Exception('Enter a UID first.');
                  final service = ProfileService();
                  final result = await service.fetchProfile(uid);
                  s._lastFetchedUid = uid;
                  return switch (result) {
                    Success<UserProfile>(:final data) =>
                      '${data.display_name} / ${data.avatar_url ?? 'none'}',
                    Failure<UserProfile>(:final message) =>
                      throw Exception(message),
                  };
                }),
        child: const Text('Fetch Profile by UID'),
      )
    ];