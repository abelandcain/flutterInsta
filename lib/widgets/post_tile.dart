import 'package:flutter/material.dart';
import 'package:flutterinstagram/pages/post_screen.dart';
import 'package:flutterinstagram/widgets/custom_image.dart';
import 'package:flutterinstagram/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;
  PostTile(this.post);
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                PostScreen(postId: post.postId, userId: post.ownerId)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:()=> showPost(context),
      child: cachedNetworkImage(post.mediaUrl),
    );
  }
}
