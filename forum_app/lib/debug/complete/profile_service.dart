import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class ProfileServicePanel extends StatefulWidget {
  final void Function(String label, Future<String> Function() action) onRun;
  final bool busy;

  const ProfileServicePanel({super.key, required this.onRun, required this.busy});

  // Test keys — not visible in the UI
  static const textFieldKey = Key('profile_text_field');
  static const fetchBtnKey = Key('profile_fetch_btn');
  static const updateNameBtnKey = Key('profile_update_name_btn');
  static const updateAvatarBtnKey = Key('profile_update_avatar_btn');

  @override
  State<ProfileServicePanel> createState() => _ProfileServicePanelState();
}

class _ProfileServicePanelState extends State<ProfileServicePanel>
    with AutomaticKeepAliveClientMixin {
  final _textController = TextEditingController();
  String? _lastFetchedUid;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  List<Widget> get buttons => [
        ElevatedButton(
          key: ProfileServicePanel.fetchBtnKey,
          onPressed: widget.busy
              ? null
              : () => widget.onRun('Fetch Profile', () async {
                    final uid = _textController.text.trim();
                    if (uid.isEmpty) throw Exception('Enter a UID first.');
                    final service = ProfileService();
                    final result = await service.fetchProfile(uid);
                    if (result is Success<UserProfile>) {
                      _lastFetchedUid = uid;
                      return '${result.data.displayName ?? 'Anonymous'} / ${result.data.avatarUrl ?? 'none'}';
                    }
                    throw Exception((result as Failure<UserProfile>).message);
                  }),
          child: const Text('Fetch Profile by UID'),
        ),
        ElevatedButton(
          key: ProfileServicePanel.updateNameBtnKey,
          onPressed: (widget.busy || _lastFetchedUid == null)
              ? null
              : () => widget.onRun('Update Name', () async {
                    final newName = _textController.text.trim();
                    if (newName.isEmpty) throw Exception('Enter a new name first.');
                    final service = ProfileService();
                    final updateResult = await service.updateProfile(_lastFetchedUid!, newName);
                    if (updateResult is Failure) {
                      throw Exception((updateResult).message);
                    }
                    final refetchResult = await service.fetchProfile(_lastFetchedUid!);
                    return switch (refetchResult) {
                      Success<UserProfile>(:final data) => data.displayName ?? 'Anonymous',
                      Failure<UserProfile>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Update Name for Last Fetched UID'),
        ),
        ElevatedButton(
          key: ProfileServicePanel.updateAvatarBtnKey,
          onPressed: (widget.busy || _lastFetchedUid == null)
              ? null
              : () => widget.onRun('Update Avatar', () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked == null) throw Exception('No image selected.');
                    final bytes = await picked.readAsBytes();
                    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'png';
                    final service = ProfileService();
                    final updateResult = await service.updateAvatar(_lastFetchedUid!, bytes, extension: ext);
                    if (updateResult is Failure) {
                      throw Exception((updateResult).message);
                    }
                    final refetchResult = await service.fetchProfile(_lastFetchedUid!);
                    return switch (refetchResult) {
                      Success<UserProfile>(:final data) => data.avatarUrl ?? 'none',
                      Failure<UserProfile>(:final message) => throw Exception(message),
                    };
                  }),
          child: const Text('Update Avatar for Last Fetched UID'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          TextField(
            key: ProfileServicePanel.textFieldKey,
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Enter UID or name...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: buttons),
        ],
      ),
    );
  }
}