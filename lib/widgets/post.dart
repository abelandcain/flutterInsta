import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/pages/comments.dart';
import 'package:flutterinstagram/pages/home.dart';
import 'package:flutterinstagram/pages/profile.dart';
import 'package:flutterinstagram/widgets/custom_image.dart';
import 'package:flutterinstagram/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId,
      ownerId,
      userName,
      location,
      description,
      mediaUrl,
      currentUserId = currentUser?.id,
      completeAddress;
  final likes;

  Post(
      {@required this.postId,
      @required this.ownerId,
      @required this.userName,
      @required this.location,
      @required this.description,
      @required this.mediaUrl,
      @required this.likes,
      @required this.completeAddress});

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc["postId"],
      ownerId: doc["ownerId"],
      userName: doc["userName"],
      location: doc["location"],
      description: doc["description"],
      mediaUrl: doc["mediaUrl"],
      likes: doc["likes"],
      completeAddress: doc["completeAddress"],
    );
  }

  int getLikeCount() {
    return likes.length;
  }

  @override
  _PostState createState() {
    int a = getLikeCount();
    return _PostState(a);
  }
}

class _PostState extends State<Post> {
  int likeCount;
  bool _isLiked;
  final int a;

  final AnimatorKey animatorKey = AnimatorKey<double>();

  _PostState(this.a);

  @override
  void initState() {
    likeCount = a;
    _isLiked = widget.likes.contains(widget.currentUserId);

    super.initState();
  }

  showProfile(context, {@required profileId}) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => Profile(profileId: profileId)));
  }

  FutureBuilder buildPostHeader() {
    return FutureBuilder(
      builder: (_, snapShot) {
        if (!snapShot.hasData) return circularProgress();

        User user = User.fromDocument(snapShot.data);
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.userName,
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          subtitle: Text(widget.location),
          trailing: IconButton(
            icon: currentUser.id == widget.ownerId
                ? Icon(Icons.more_vert)
                : Text(""),
            onPressed: () => handleDeletePosts(context),
          ),
        );
      },
      future: userRef.document(widget.ownerId).get(),
    );
  }

  void handleLikePost() {
    _isLiked = widget.likes.contains(widget.currentUserId);

    if (_isLiked) {
      setState(() {
        likeCount -= 1;
        _isLiked = false;
        widget.likes.remove(widget.currentUserId);
      });
      removeLikeFromActivityFeed();
      postRef
          .document(widget.ownerId)
          .collection('userPosts')
          .document(widget.postId)
          .updateData({
        "likes": FieldValue.arrayRemove([widget.currentUserId])
      });
    } else {
      animatorKey.triggerAnimation(restart: true);
      setState(() {
        likeCount += 1;
        _isLiked = true;
        widget.likes.add(widget.currentUserId);
      });
      addLikeToActivityFeed();
      postRef
          .document(widget.ownerId)
          .collection('userPosts')
          .document(widget.postId)
          .updateData({
        "likes": FieldValue.arrayUnion([widget.currentUserId])
      });
    }
  }

  removeLikeFromActivityFeed() {
    activityFeedref
        .document(widget.ownerId)
        .collection("feedItems")
        .document(widget.postId)
        .get()
        .then((value) => value.reference.delete());
  }

  addLikeToActivityFeed() {
    activityFeedref
        .document(widget.ownerId)
        .collection("feedItems")
        .document(widget.postId)
        .setData({
      "type": "like",
      "userName": currentUser.userName,
      "userId": currentUser.id,
      "userProfileImg": currentUser.photoUrl,
      "postId": widget.postId,
      "mediaUrl": widget.mediaUrl,
      "timestamp": DateTime.now()
    });
  }

  GestureDetector buildPostImage() {
    return GestureDetector(
      onDoubleTap: () {
        handleLikePost();
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(
            widget.mediaUrl,
          ),
          Animator<double>(
              animatorKey: animatorKey,
              duration: Duration(seconds: 1),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.elasticInOut,
              cycles: 2,
              builder: (_, anim, __) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red[100].withOpacity(0.5),
                    ),
                  )),
          AnimatorRebuilder(
              observe: () => animatorKey,
              builder: (ctx, anim, child) => Transform.scale(
                    scale: anim.value,
                    child: Icon(
                      Icons.favorite,
                      size: 80.0,
                      color: Colors.red[100].withOpacity(0.5),
                    ),
                  ))
        ],
      ),
    );
  }

  handleDeletePosts(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(
          "Remove This Post?",
        ),
        children: <Widget>[
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              deletePost();
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
            ),
          )
        ],
      ),
    );
  }

  void deletePost() async {
    postRef
        .document(widget.ownerId)
        .collection("userPosts")
        .document(widget.postId)
        .get()
        .then((value) => value.reference.delete());

    storageRef.child("post_${widget.postId}.jpg").delete();
    var del = await activityFeedref
        .document(widget.ownerId)
        .collection("feedItems")
        .where('postId', isEqualTo: widget.postId)
        .getDocuments();
    del.documents.forEach((element) {
      if (element.exists) element.reference.delete();
    });

    var del2 = await commentRef
        .document(widget.postId)
        .collection("comments")
        .getDocuments();
    del2.documents.forEach((element) {
      if (element.exists) element.reference.delete();
    });
  }

  Widget buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            IconButton(
              icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red[300], size: 28),
              onPressed: handleLikePost,
            ),
            IconButton(
              icon: Icon(Icons.chat, color: Colors.blue[900], size: 28),
              onPressed: () {
                showComments(context,
                    postId: widget.postId,
                    ownerId: widget.ownerId,
                    mediaUrl: widget.mediaUrl);
              },
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.only(left: 10, top: 0),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: "LearningCurve",
                    fontSize: 20),
              ),
            ),
          ],
        ),
        Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(left: 10, top: 10),
            child: RichText(
              text: TextSpan(
                  text: widget.userName,
                  style: TextStyle(
                      fontFamily: "LearningCurve",
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontSize: 30),
                  children: [
                    TextSpan(
                        text: "  "),
                    TextSpan(
                        text: widget.description,
                        style:Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15))
                  ]),
            )
            // Text(
            //   widget.userName + "   " + widget.description,
            //   softWrap: true,
            //   textAlign: TextAlign.start,
            //   style: TextStyle(
            //       fontFamily: "LearningCurve",
            //       fontWeight: FontWeight.bold,
            //       fontSize: 30),
            // ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
        Divider(
          color: Colors.blueGrey,
          thickness: 1,
        )
      ],
    );
  }

  showComments(BuildContext context,
      {String postId, String ownerId, String mediaUrl}) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Comments(
              postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl),
        ));
  }
}
