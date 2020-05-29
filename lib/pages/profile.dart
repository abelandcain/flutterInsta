import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/pages/edit_profile.dart';
import 'package:flutterinstagram/widgets/header.dart';
import 'package:flutterinstagram/widgets/post.dart';
import 'package:flutterinstagram/widgets/post_tile.dart';
import 'package:flutterinstagram/widgets/progress.dart';
import "./home.dart";

class Profile extends StatefulWidget {
  final String profileId;

  const Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String postOrientation = "grid";
  bool isFollowing = false;
  bool isLoading = false;
  int postCount = 0;
  int followerCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  @override
  void initState() {
    checkIfFollowing();
    getFollowers();
    getFollowing();
    getProfilePosts();

    super.initState();
  }

  getFollowers() async {
    final snapshots = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .getDocuments();
    setState(() {
      followerCount = snapshots.documents.length;
    });
  }

  getFollowing() async{
    final snapshots = await followingRef
        .document(widget.profileId)
        .collection("userFollowing")
        .getDocuments();
    setState(() {
      followingCount = snapshots.documents.length;
    });
  }
  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .get();
  
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getProfilePosts() async {
    print("hi");
    setState(() {
      isLoading = true;
    });
    final snapShot = await postRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    setState(() {
      isLoading = false;
      postCount = snapShot.documents.length;
      posts = snapShot.documents.map((e) => Post.fromDocument(e)).toList();
    });
  }

  final String currentUserId = currentUser?.id;
  buildCountColumn(String label, int count) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
              color: Colors.grey, fontWeight: FontWeight.w400, fontSize: 15),
        )
      ],
    );
  }

  editProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => EditProfile(currentUserId: currentUserId),
      ),
    );
    setState(() {});
  }

  buttonStructure(String text, Function func) {
    return SizedBox(
      width: double.infinity,
      height: 27,
      child: FlatButton(
        onPressed: func,
        child: Text(
          text,
          style: TextStyle(color: isFollowing ? Colors.black : Colors.white),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        color: isFollowing ? Colors.white : Colors.blue,
      ),
    );
  }

  buildProfileButton() {
    if (currentUserId == widget.profileId)
      return buttonStructure("Edit Profile", editProfile);
    else if (isFollowing) {
      return buttonStructure("Unfollow", handleunFollowUser);
    } else if (!isFollowing) return buttonStructure("Follow", handlefollowUser);
  }

  handleunFollowUser() async {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .delete();

    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .delete();

    activityFeedref
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUserId)
        .delete();
  }

  handlefollowUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .document(widget.profileId)
        .collection("userFollowers")
        .document(currentUserId)
        .setData({});

    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .setData({});

    activityFeedref
        .document(widget.profileId)
        .collection("feedItems")
        .document(currentUserId)
        .setData({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser.userName,
      "userId": currentUserId,
      "userProfileImg": currentUser.photoUrl,
      "timestamp": DateTime.now()
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: userRef.document(widget.profileId).get(),
      builder: (_, snapShot) {
        if (!snapShot.hasData) return circularProgress();
        User user = User.fromDocument(snapShot.data);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          buildCountColumn("posts", postCount),
                          buildCountColumn("followers", followerCount),
                          buildCountColumn("following", followingCount)
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      buildProfileButton(),
                    ],
                  ))
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12.0),
                child: Text(
                  user.userName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2.0),
                child: Text(
                  user.bio,
                  style: TextStyle(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePost() {
    if (isLoading)
      return circularProgress();
    else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SvgPicture.asset("assets/images/no_content.svg", height: 260),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                "NO Posts",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> gridTiles = [];
      posts.forEach((element) {
        return gridTiles.add(GridTile(child: PostTile(element)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        children: gridTiles,
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
      );
    } else {
      return Column(
        children: posts,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: header(context, titleText: "Profile"),
        body: ListView(
          children: <Widget>[
            buildProfileHeader(),
            Divider(),
            buildTogglePostOrientation(),
            Divider(height: 0.0),
            buildProfilePost(),
          ],
        ));
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
            icon: Icon(
              Icons.grid_on,
              color: postOrientation == "grid"
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                postOrientation = "grid";
              });
            }),
        IconButton(
            icon: Icon(
              Icons.list,
              color: postOrientation == "list"
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                postOrientation = "list";
              });
            })
      ],
    );
  }
}
