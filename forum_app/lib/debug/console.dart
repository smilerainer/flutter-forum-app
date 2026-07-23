import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
                  if (result is Success<UserProfile>) {
                    s._lastFetchedUid = uid;
                    return '${result.data.displayName} / ${result.data.avatarUrl ?? 'none'}';
                  }
                  throw Exception((result as Failure<UserProfile>).message);
                }),
        child: const Text('Fetch Profile by UID'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastFetchedUid == null)
            ? null
            : () => s.run('Update Name', () async {
                  final newName = s._textController.text.trim();
                  if (newName.isEmpty) throw Exception('Enter a new name first.');
                  final service = ProfileService();
                  final updateResult = await service.updateProfile(s._lastFetchedUid!, newName);
                  if (updateResult is Failure) {
                    throw Exception((updateResult as Failure).message);
                  }
                  final refetchResult = await service.fetchProfile(s._lastFetchedUid!);
                  return switch (refetchResult) {
                    Success<UserProfile>(:final data) => data.displayName,
                    Failure<UserProfile>(:final message) =>
                      throw Exception(message),
                  };
                }),
        child: const Text('Update Name for Last Fetched UID'),
      ),
      ElevatedButton(
        onPressed: (s._busy || s._lastFetchedUid == null)
            ? null
            : () => s.run('Update Avatar', () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked == null) throw Exception('No image selected.');
                  final bytes = await picked.readAsBytes();
                  final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
                  final service = ProfileService();
                  final updateResult = await service.updateAvatar(s._lastFetchedUid!, bytes, extension: ext);
                  if (updateResult is Failure) {
                    throw Exception((updateResult as Failure).message);
                  }
                  final refetchResult = await service.fetchProfile(s._lastFetchedUid!);
                  return switch (refetchResult) {
                    Success<UserProfile>(:final data) =>
                      data.avatarUrl ?? 'none',
                    Failure<UserProfile>(:final message) =>
                      throw Exception(message),
                  };
                }),
        child: const Text('Update Avatar for Last Fetched UID'),
      ),
    ];