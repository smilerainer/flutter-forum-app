import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/logic/post_list_view_model.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_card.dart';
import 'package:forum_app/core/result.dart';
import 'package:forum_app/features/profile/data/profile_service.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

class PostListScreen extends StatefulWidget {
  final ProfileService? profileService;
  final PostService? postService;

  const PostListScreen({super.key, this.profileService, this.postService});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late final PostListViewModel _viewModel;
  UserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _viewModel = PostListViewModel(widget.postService ?? PostService());
    _viewModel.loadInitial();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final uid = context.read<AuthViewModel>().user?.id;
    if (uid == null) return;
    final result = await (widget.profileService ?? ProfileService()).fetchProfile(uid);
    if (!mounted) return;
    if (result is Success<UserProfile>) {
      setState(() {
        _currentUserProfile = result.data;
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification, PostListViewModel vm) {
    if (notification is ScrollEndNotification && notification.metrics.pixels >=
        notification.metrics.maxScrollExtent - 200) {
      vm.loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Feed'),
            actions: [
              if (authVm.isLoggedIn)
                IconButton(
                  tooltip: 'Profile',
                  icon: const Icon(Icons.person),
                  onPressed: () {
                    final uid = authVm.user?.id;
                    if (uid != null) {
                      context.push('/profile/$uid');
                    }
                  },
                ),
              if (authVm.isLoggedIn)
                TextButton(
                  key: const Key('post_list_sign_out_btn'),
                  onPressed: () => authVm.signOut(),
                  child: const Text('Sign out'),
                )
              else
                TextButton(
                  key: const Key('post_list_log_in_btn'),
                  onPressed: () => context.go('/login'),
                  child: const Text('Log in'),
                ),
            ],
          ),
          body: _buildBody(_viewModel),
        );
      },
    );
  }

  Widget _buildBody(PostListViewModel vm) {
    final authVm = context.watch<AuthViewModel>();

    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.error != null && vm.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: ${vm.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: vm.loadInitial,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (vm.items.isEmpty) {
      return _buildEmptyState(vm);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onScrollNotification(notification, vm),
      child: RefreshIndicator(
        onRefresh: vm.loadInitial,
        child: ListView.builder(
          itemCount: vm.items.length + (vm.hasMore ? 1 : 0) + (authVm.isLoggedIn ? 1 : 0),
          itemBuilder: (context, index) {
            final hasCreatePrompt = authVm.isLoggedIn;
            if (hasCreatePrompt && index == 0) {
              return _buildCreatePrompt();
            }
            final adjustedIndex = hasCreatePrompt ? index - 1 : index;
            if (adjustedIndex == vm.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = vm.items[adjustedIndex];
            return PostCard(
              post: post,
              onTap: () => context.push('/posts/${post.id}', extra: post),
              onAuthorTap: post.author != null
                  ? () => context.push('/profile/${post.author!.id}')
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreatePrompt() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/posts/create'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _currentUserProfile?.avatarUrl != null
                      ? NetworkImage(_currentUserProfile!.avatarUrl!)
                      : null,
                  child: _currentUserProfile?.avatarUrl == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make a post...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(PostListViewModel vm) {
    final authVm = context.watch<AuthViewModel>();
    return RefreshIndicator(
      onRefresh: vm.loadInitial,
      child: ListView(
        children: [
          if (authVm.isLoggedIn) _buildCreatePrompt(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}