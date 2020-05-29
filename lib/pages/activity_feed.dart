import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterinstagram/pages/home.dart';
import 'package:flutterinstagram/pages/post_screen.dart';
import 'package:flutterinstagram/pages/profile.dart';
import 'package:flutterinstagram/widgets/header.dart';
import 'package:flutterinstagram/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeago;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, titleText: "Activity Feed"),
        body: Container(
          child: StreamBuilder(
            builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return circularProgress();

              List<ActivityFeedItem> feedItems = [];
              snapshot.data.documents.forEach((element) {
                feedItems.add(ActivityFeedItem.fromDocument(element));
              });

              return ListView(
                children: feedItems,
              );
            },
            stream: activityFeedref
                .document(currentUser.id)
                .collection("feedItems")
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
          ),
        ));
  }
}

Widget mediaPreview;
String activityText;

class ActivityFeedItem extends StatelessWidget {
  final String userName,
      userId,
      type,
      mediaUrl,
      postId,
      userProfileImage,
      commentData;
  final Timestamp timestamp;

  ActivityFeedItem(
      {@required this.userName,
      @required this.userId,
      @required this.type,
      @required this.mediaUrl,
      @required this.postId,
      @required this.userProfileImage,
      @required this.commentData,
      @required this.timestamp});
  factory ActivityFeedItem.fromDocument(DocumentSnapshot doc) {
    return ActivityFeedItem(
        userName: doc["userName"],
        userId: doc["userId"],
        type: doc["type"],
        mediaUrl: doc["mediaUrl"],
        postId: doc["postId"],
        userProfileImage: doc["userProfileImg"],
        commentData: doc["commentData"],
        timestamp: doc["timestamp"]);
  }
  showPost(context) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PostScreen(postId: postId, userId: userId)));
  }

  showProfile(context, {profileId}) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => Profile(profileId: profileId)));
  }

  configureMediaPreview(context) {
    if (type == "like" || type == "comment") {
      mediaPreview = GestureDetector(
          onTap: () => showPost(context),
          child: Container(
            height: 50,
            width: 50,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: CachedNetworkImageProvider(mediaUrl),
                        fit: BoxFit.cover)),
              ),
            ),
          ));
    } else
      mediaPreview = Text("aa");

    if (type == "like")
      activityText = "liked your post";
    else if (type == "follow")
      activityText = "is following you";
    else if (type == "comment") activityText = "replied:$commentData";
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
        padding: EdgeInsets.only(bottom: 2),
        child: Container(
          child: ListTile(
            title: GestureDetector(
              onTap: () => showProfile(context, profileId: userId),
              child: RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black),
                    children: [
                      TextSpan(
                          text: userName,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: ' $activityText'),
                    ]),
              ),
            ),
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(userProfileImage),
            ),
            subtitle: Text(
              timeago.format(timestamp.toDate()),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: mediaPreview,
          ),
        ));
  }
}
