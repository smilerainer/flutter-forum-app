import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:forum_app/core/data/supabase_service.dart';
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
  // ignore: unused_field
  bool _busy = false;

  String? lastUploadPath;
  List<String>? lastBatchPaths;
  String? lastProfileUid;
  String? lastProfileDisplayName;
  String? lastProfileAvatarPath;

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

// ignore: library_private_types_in_public_api
Future<void> _fetchProfile(_DebugConsoleState s) async {
  final uid = SupabaseService.client.auth.currentUser?.id;
  if (uid == null) {
    s.run('Fetch Profile', () async => throw Exception('Not signed in'));
    return;
  }
  s.run('Fetch Profile', () async {
    final service = ProfileService();
    final result = await service.fetchProfile(uid);
    if (result is Success<UserProfile>) {
      s.lastProfileUid = uid;
      s.lastProfileDisplayName = result.data.displayName;
      s.lastProfileAvatarPath = result.data.avatarUrl;
      return '${result.data.displayName ?? "Anonymous"} / ${result.data.avatarUrl ?? "none"}';
    }
    throw Exception((result as Failure<UserProfile>).message);
  });
}

Future<void> _updateName(_DebugConsoleState s) async {
  if (s.lastProfileUid == null) {
    s.run('Update Name', () async => throw Exception('Fetch profile first'));
    return;
  }
  s.run('Update Name', () async {
    final newName = 'Debug ${DateTime.now().second}';
    final service = ProfileService();
    final updateResult = await service.updateProfile(s.lastProfileUid!, newName);
    if (updateResult is Failure<void>) {
      throw Exception(updateResult.message);
    }
    final refetchResult = await service.fetchProfile(s.lastProfileUid!);
    return switch (refetchResult) {
      Success<UserProfile>(:final data) => data.displayName ?? 'Anonymous',
      Failure<UserProfile>(:final message) => throw Exception(message),
    };
  });
}

Future<void> _updateAvatar(_DebugConsoleState s) async {
  if (s.lastProfileUid == null) {
    s.run('Update Avatar', () async => throw Exception('Fetch profile first'));
    return;
  }
  s.run('Update Avatar', () async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) throw Exception('No image selected.');
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
    final service = ProfileService();
    final updateResult = await service.updateAvatar(s.lastProfileUid!, bytes, extension: ext);
    if (updateResult is Failure<String>) {
      throw Exception(updateResult.message);
    }
    final refetchResult = await service.fetchProfile(s.lastProfileUid!);
    return switch (refetchResult) {
      Success<UserProfile>(:final data) => data.avatarUrl ?? 'none',
      Failure<UserProfile>(:final message) => throw Exception(message),
    };
  });
}

// ignore: library_private_types_in_public_api
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy ? null : () => _fetchProfile(s),
        child: const Text('Fetch My Profile'),
      ),
      ElevatedButton(
        onPressed: s._busy || s.lastProfileUid == null ? null : () => _updateName(s),
        child: const Text('Update Name'),
      ),
      ElevatedButton(
        onPressed: s._busy || s.lastProfileUid == null ? null : () => _updateAvatar(s),
        child: const Text('Update Avatar'),
      ),
    ];
