import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterinstagram/widgets/header.dart';
import 'package:flutterinstagram/widgets/progress.dart';
import "./home.dart";
import "package:timeago/timeago.dart" as timeago;

class Comments extends StatefulWidget {
  final String postId, postOwnerId, postMediaUrl;

  Comments({this.postId, this.postOwnerId, this.postMediaUrl});
  @override
  CommentsState createState() => CommentsState(
      postId: this.postId,
      postOwnerId: this.postOwnerId,
      postMediaUrl: this.postMediaUrl);
}

class CommentsState extends State<Comments> {
  final String postId, postOwnerId, postMediaUrl;

  CommentsState({this.postId, this.postOwnerId, this.postMediaUrl});
  final TextEditingController commentController = TextEditingController();
  buildComments() {
    return StreamBuilder(
      stream: commentRef
          .document(postId)
          .collection("comments")
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (ctx, AsyncSnapshot<QuerySnapshot> snpashot) {
        if (!snpashot.hasData) return circularProgress();
        List<Comment> comments = [];
        snpashot.data.documents.forEach((element) {
          comments.add(Comment.fromDocument(element));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComment() async {
   commentRef.document(postId).collection("comments").add({
      "userName": currentUser.userName,
      "comment": commentController.text,
      "timestamp": DateTime.now(),
      "avatarUrl": currentUser.photoUrl,
      "userId": currentUser.id
    });
    if(postOwnerId != currentUser.id)
     activityFeedref.document(postOwnerId).collection("feedItems").add({
   "type":"comment",
   "commentData":commentController.text,
   "userName": currentUser.userName,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "postId": widget.postId,
      "mediaUrl": postMediaUrl,
      "timestamp": DateTime.now()
 });
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: <Widget>[
          Expanded(child: buildComments()),
          Divider(),
          ListTile(
              title: TextFormField(
                controller: commentController,
                decoration: InputDecoration(labelText: "Write a comment....."),
              ),
              trailing: OutlineButton(
                onPressed: addComment,
                borderSide: BorderSide.none,
                child: Text("Post"),
              ))
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String userName, userId, avatarUrl, comment;
  final Timestamp timestamp;

  Comment(
      {@required this.userName,
      @required this.userId,
      @required this.avatarUrl,
      @required this.comment,
      @required this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
        userName: doc["userName"],
        userId: doc["userId"],
        avatarUrl: doc["avatarUrl"],
        comment: doc["comment"],
        timestamp: doc["timestamp"]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(avatarUrl),
          ),
          subtitle: Text(timeago.format(timestamp.toDate())),
        ),
        Divider()
      ],
    );
  }
}
