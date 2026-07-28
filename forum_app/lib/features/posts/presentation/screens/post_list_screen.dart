import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:forum_app/features/auth/logic/auth_view_model.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/logic/post_list_view_model.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  State<PostListScreen> createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  late final PostListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PostListViewModel(PostService());
    _viewModel.loadInitial();
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
          floatingActionButton: authVm.isLoggedIn
              ? FloatingActionButton(
                  onPressed: () => context.go('/posts/create'),
                  child: const Icon(Icons.add),
                )
              : null,
          body: _buildBody(_viewModel),
        );
      },
    );
  }

  Widget _buildBody(PostListViewModel vm) {
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
          itemCount: vm.items.length + (vm.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == vm.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final post = vm.items[index];
            return PostCard(
              post: post,
              onTap: () => context.push('/posts/${post.id}', extra: post),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(PostListViewModel vm) {
    return RefreshIndicator(
      onRefresh: vm.loadInitial,
      child: ListView(
        children: [
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
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create one!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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