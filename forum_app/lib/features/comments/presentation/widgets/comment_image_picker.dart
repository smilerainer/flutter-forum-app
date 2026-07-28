import 'package:flutter/material.dart';
import 'package:forum_app/core/widgets/image_picker_widget.dart';

class CommentImagePicker extends StatelessWidget {
  final OnImagesChanged? onImagesChanged;

  const CommentImagePicker({super.key, this.onImagesChanged});

  @override
  Widget build(BuildContext context) {
    return ImagePickerWidget(onImagesChanged: onImagesChanged);
  }
}