import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:forum_app/core/validators.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/profile/logic/profile_view_model.dart';
import 'package:forum_app/features/profile/presentation/widgets/profile_photo_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileViewModel _viewModel;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authVm = context.read<AuthViewModel>();
    _viewModel = ProfileViewModel(authViewModel: authVm);
    _viewModel.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _viewModel.dispose();
    super.dispose();
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
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final displayName = _viewModel.profile?.displayName ?? '';
        final avatarUrl = _viewModel.profile?.avatarUrl;

        if (_viewModel.profile != null &&
            _nameController.text != (_viewModel.profile!.displayName ?? '')) {
          _nameController.text = _viewModel.profile!.displayName ?? '';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              if (_viewModel.profile != null && !_viewModel.isSaving)
                IconButton(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  tooltip: 'Save',
                ),
              if (_viewModel.isSaving)
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ProfilePhotoPicker(
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
                  ),
                ),
                const SizedBox(height: 24),
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
                  displayName.isEmpty ? 'No display name set' : displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (_viewModel.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _viewModel.error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}