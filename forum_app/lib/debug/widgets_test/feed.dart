import 'package:flutter/material.dart';
import 'package:forum_app/features/posts/data/post_service.dart';
import 'package:forum_app/features/posts/logic/post_list_view_model.dart';
import 'package:forum_app/features/posts/presentation/widgets/post_card.dart';

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
  PostListViewModel? _postListVm;

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
    final posts = _postListVm?.items ?? [];
    final isLoading = _postListVm?.isLoading ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('DEBUG CONSOLE')),
      body: Column(children: [
        Wrap(spacing: 8, runSpacing: 8, children: buttons(this)),
        const Divider(),
        // Post cards area
        Expanded(
          child: isLoading && posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : posts.isEmpty
                  ? const Center(child: Text('No posts loaded'))
                  : ListView.builder(
                      itemCount: posts.length + (isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return PostCard(post: posts[index]);
                      },
                    ),
        ),
        const Divider(),
        // Log area
        SizedBox(
          height: 150,
          child: ListView(
            reverse: true,
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
List<Widget> buttons(_DebugConsoleState s) => [
      ElevatedButton(
        onPressed: s._busy
            ? null
            : () => s.run('Load Posts', () async {
                  s._postListVm = PostListViewModel(PostService());
                  await s._postListVm!.loadInitial();
                  final first = s._postListVm!.items.isNotEmpty ? s._postListVm!.items.first : null;
                  return 'count=${s._postListVm!.items.length}, hasMore=${s._postListVm!.hasMore}, firstAuthor=${first?.author?.displayName ?? 'null'}, firstAuthorId=${first?.author?.id ?? 'null'}';
                }),
        child: const Text('Load Posts'),
      ),
      ElevatedButton(
        onPressed: s._busy || s._postListVm == null
            ? null
            : () => s.run('Load More', () async {
                  await s._postListVm!.loadMore();
                  return 'count=${s._postListVm!.items.length}';
                }),
        child: const Text('Load More'),
      ),
    ];