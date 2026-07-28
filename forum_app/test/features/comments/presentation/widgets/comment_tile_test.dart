import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forum_app/core/data/image_ref.dart';
import 'package:forum_app/features/comments/data/comment.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:forum_app/features/profile/data/user_profile.dart';

void main() {
  final baseTime = DateTime(2026, 1, 1, 12, 0, 0);

  Widget wrap(CommentTile tile) => MaterialApp(home: Scaffold(body: tile));

  testWidgets('renders body and author name', (tester) async {
    final comment = Comment(
      id: 'c-1',
      body: 'hello world',
      postId: 'p-1',
      userId: 'u-1',
      images: [],
      createdAt: baseTime,
    );

    await tester.pumpWidget(wrap(CommentTile(comment: comment)));

    expect(find.text('hello world'), findsOneWidget);
    expect(find.text('Unknown'), findsOneWidget);
  });

  testWidgets('shows author name when author is present', (tester) async {
    final comment = Comment(
      id: 'c-1',
      body: 'test',
      postId: 'p-1',
      userId: 'u-1',
      images: [],
      author: UserProfile(
        id: 'u-1',
        displayName: 'Alice',
        avatarUrl: null,
        createdAt: baseTime,
      ),
      createdAt: baseTime,
    );

    await tester.pumpWidget(wrap(CommentTile(comment: comment)));

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Unknown'), findsNothing);
  });

  testWidgets('shows image grid when images are present', (tester) async {
    final comment = Comment(
      id: 'c-1',
      body: 'with image',
      postId: 'p-1',
      userId: 'u-1',
      images: [
        ImageRef(id: 'img-1', storagePath: 'debug/test.png', position: 0),
      ],
      createdAt: baseTime,
    );

    await tester.pumpWidget(wrap(CommentTile(comment: comment)));

    expect(find.text('with image'), findsOneWidget);
  });
}
