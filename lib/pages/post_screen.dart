import 'package:flutter/material.dart';
import 'package:flutterinstagram/pages/home.dart';
import 'package:flutterinstagram/widgets/header.dart';
import 'package:flutterinstagram/widgets/post.dart';
import 'package:flutterinstagram/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId, postId;

  const PostScreen({this.userId, this.postId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postRef
          .document(userId)
          .collection("userPosts")
          .document(postId)
          .get(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return circularProgress();
        Post post = Post.fromDocument(snapshot.data);
        return Center(
            child: Scaffold(
          appBar: header(context, titleText: post.description),
          body: ListView(
            children: <Widget>[
              Container(
                child: post,
              )
            ],
          ),
        ));
      },
    );
  }
}
