import 'package:flutter/material.dart';
import 'package:forum_app/debug/complete/post_service.dart';
import 'package:forum_app/debug/complete/comments_service.dart';
import 'package:forum_app/debug/complete/profile_service.dart';
import 'package:forum_app/debug/complete/storage_service.dart';

class CompleteDebugConsole extends StatefulWidget {
  const CompleteDebugConsole({super.key});
  @override
  State<CompleteDebugConsole> createState() => _CompleteDebugConsoleState();
}

class _CompleteDebugConsoleState extends State<CompleteDebugConsole>
    with SingleTickerProviderStateMixin {
  final List<String> _log = [];
  bool _busy = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

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
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG COMPLETE'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'POSTS'),
            Tab(text: 'COMMENTS'),
            Tab(text: 'PROFILE'),
            Tab(text: 'STORAGE'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PostServicePanel(onRun: run, busy: _busy),
                CommentsServicePanel(onRun: run, busy: _busy),
                ProfileServicePanel(onRun: run, busy: _busy),
                StorageServicePanel(onRun: run, busy: _busy),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 200,
            child: ListView(
              reverse: true,
              children: _log
                  .map((l) => Padding(
                        padding: const EdgeInsets.all(4),
                        child: SelectableText(
                          l,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}