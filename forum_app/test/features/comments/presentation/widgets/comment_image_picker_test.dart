import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forum_app/core/widgets/image_picker_widget.dart';
import 'package:forum_app/features/comments/presentation/widgets/comment_image_picker.dart';

void main() {
  testWidgets('renders the pick button', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CommentImagePicker())),
    );

    expect(find.text('Pick Images from Gallery'), findsOneWidget);
  });

  testWidgets('calls onImagesChanged when images are picked via override', (tester) async {
    final picked = <List<PickerImage>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentImagePicker(
            onImagesChanged: (images) => picked.add(images),
          ),
        ),
      ),
    );

    expect(find.text('Pick Images from Gallery'), findsOneWidget);
  });
}