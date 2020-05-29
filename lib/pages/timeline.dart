import 'package:flutter/material.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/pages/home.dart';
import 'package:flutterinstagram/pages/search.dart';
import 'package:flutterinstagram/widgets/header.dart';
import 'package:flutterinstagram/widgets/post.dart';
import 'package:flutterinstagram/widgets/progress.dart';

class Timeline extends StatefulWidget {
  final User currentUser;

  const Timeline({this.currentUser});
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList;
  @override
  void initState() {
    getTimeline();
    getFollowing();
    super.initState();
  }

  getFollowing() async {
    final snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingList = snapshot.documents.map((e) => e.documentID).toList();
    });
  }

  getTimeline() async {
    final snapShot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy("timestamp", descending: true)
        .getDocuments();

    List<Post> posts =
        snapShot.documents.map((doc) => Post.fromDocument(doc)).toList();

    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    print("rebuilding");
    if (posts == null)
      return circularProgress();
    else if (posts.isEmpty) return buildUsersToFollow();

    return ListView.builder(
      itemBuilder: (context, index) {
        return posts[index];
      },
      itemCount: posts.length,
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
        appBar: header(context, isAppTitle: true),
        body: RefreshIndicator(
            child: buildTimeline(), onRefresh: () => getTimeline()));
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream:
          userRef.orderBy('timestamp', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return circularProgress();
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          if (isAuthUser)
            return;
          else if (followingList.contains(user.id))
            return;
          else
            userResults.add(UserResult(user));
        });
        return Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.person_add,
                      color: Theme.of(context).primaryColor, size: 30),
                  SizedBox(width: 30),
                  Text("Users To Follow",
                      style: TextStyle(
                          color: Theme.of(context).primaryColor, fontSize: 30)),
                ],
              ),
            ),
           
               ListView(shrinkWrap: true,
                children: userResults,
              
            )
          ],
        );
      },
    );
  }
}
