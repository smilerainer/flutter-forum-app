import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forum_app/core/validators.dart';
import 'package:forum_app/core/widgets/image_preview_dialog.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/profile/logic/profile_view_model.dart';
import 'package:forum_app/features/profile/presentation/widgets/profile_photo_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String profileId;

  const ProfileScreen({super.key, required this.profileId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    _viewModel = ProfileViewModel(authViewModel: authVm);
    _viewModel.load(profileId: widget.profileId);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileId != widget.profileId) {
      _viewModel.load(profileId: widget.profileId);
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  bool get _isOwnProfile {
    final currentUserId = context.read<AuthViewModel>().user?.id;
    return currentUserId != null && _viewModel.profile?.id == currentUserId;
  }

  Future<void> _save() async {
    final name = _nameController.text;
    final nameError = Validators.displayName(name);
    if (nameError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nameError)),
      );
      return;
    }

    await _viewModel.updateName(name);

    if (mounted) {
      if (_viewModel.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_viewModel.error!)),
        );
      } else {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading && _viewModel.profile == null) {
          return Scaffold(
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final profile = _viewModel.profile;
        final displayName = profile?.displayName ?? '';
        final avatarUrl = profile?.avatarUrl;
        final createdAt = profile?.createdAt;

        if (profile != null &&
            _nameController.text != (profile.displayName ?? '')) {
          _nameController.text = profile.displayName ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(displayName.isEmpty ? 'Profile' : displayName),
            actions: [
              if (_isOwnProfile && !_isEditing)
                IconButton(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit profile',
                ),
              if (_isOwnProfile && _isEditing && !_viewModel.isSaving)
                IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  tooltip: 'Save',
                ),
              if (_isOwnProfile && _isEditing && _viewModel.isSaving)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: _isOwnProfile && _isEditing
              ? _buildEditBody(avatarUrl)
              : _buildReadOnlyBody(displayName, avatarUrl, createdAt),
        );
      },
    );
  }

  Widget _buildEditBody(String? avatarUrl) {
    return _buildBody(
      avatarUrl: avatarUrl,
      editableAvatar: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
            enabled: !_viewModel.isSaving,
          ),
          const SizedBox(height: 8),
          Text(
            (_viewModel.profile?.displayName ?? '').isEmpty ? 'No display name set' : _viewModel.profile!.displayName!,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyBody(String displayName, String? avatarUrl, DateTime? createdAt) {
    final theme = Theme.of(context);
    final formattedDate = createdAt != null
        ? '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}'
        : 'Unknown';

    return _buildBody(
      avatarUrl: avatarUrl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayName.isEmpty ? 'Unknown' : displayName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_viewModel.profile?.isAdmin ?? false) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('Admin', style: TextStyle(fontSize: 12)),
                  backgroundColor: theme.colorScheme.primaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Member since $formattedDate',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody({String? avatarUrl, required Widget child, bool editableAvatar = false}) {
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            editableAvatar
                ? ProfilePhotoPicker(
                    currentAvatarUrl: avatarUrl,
                    isSaving: _viewModel.isSaving,
                    onAvatarChanged: (pick) {
                      if (pick == null) {
                        _viewModel.removeAvatar();
                      } else {
                        final (bytes, ext) = pick;
                        _viewModel.updateAvatar(bytes, extension: ext);
                      }
                    },
                  )
                : GestureDetector(
                    onTap: () => showImagePreview(context, avatarUrl),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.surfaceContainerHighest,
                        image: hasAvatar
                            ? DecorationImage(
                                image: NetworkImage(avatarUrl),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: !hasAvatar
                          ? Icon(Icons.person, size: 60, color: theme.colorScheme.onSurfaceVariant)
                          : null,
                    ),
                  ),
            const SizedBox(height: 24),
            if (child is Column) ...child.children,
            if (child is! Column) child,
            if (_viewModel.error != null) ...[
              const SizedBox(height: 12),
              Text(
                _viewModel.error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}