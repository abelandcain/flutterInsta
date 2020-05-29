import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/pages/activity_feed.dart';
import 'package:flutterinstagram/pages/create_account.dart';
import 'package:flutterinstagram/pages/profile.dart';
import 'package:flutterinstagram/pages/search.dart';
import 'package:flutterinstagram/pages/timeline.dart';
import 'package:flutterinstagram/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final userRef = Firestore.instance.collection("users");
final postRef = Firestore.instance.collection("posts");
final commentRef = Firestore.instance.collection("comments");
final activityFeedref = Firestore.instance.collection("feed");
final followersRef = Firestore.instance.collection("followers");
final followingRef = Firestore.instance.collection("following");
final timelineRef = Firestore.instance.collection("timeline");
final StorageReference storageRef = FirebaseStorage.instance.ref();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int page = 2;
  bool _isAuth = false;
  PageController _pageController;

  @override
  void initState() {
    autoLogin();
    _pageController = PageController(initialPage: 2);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Upload(
            currentUser: currentUser,
          ),
          ActivityFeed(),
          Timeline(currentUser:currentUser),
          Search(),
          Profile(profileId: currentUser?.id),
        ],
        controller: _pageController,
        onPageChanged: (newPage) {
          setState(() {
            page = newPage;
          });
        },
      ),
      // appBar: AppBar(
      //   actions: <Widget>[
      //     FlatButton(onPressed: logout, child: Text("logout")),
      //   ],
      // ),
      bottomNavigationBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.photo_camera)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(icon: Icon(Icons.whatshot, size: 35)),
          BottomNavigationBarItem(icon: Icon(Icons.search)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle))
        ],
        currentIndex: page,
        onTap: (value) => _pageController.animateToPage(value,
            duration: Duration(milliseconds: 300), curve: Curves.easeInQuad),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future logout() async {
    await googleSignIn.signOut();
    setState(() {
      _isAuth = false;
    });
  }

  Future autoLogin() async {
    try {
      final accountDetail =
          await googleSignIn.signInSilently(suppressErrors: false);
      handleSignin(accountDetail);
    } catch (error) {
      print("Error Signing In: $error");
    }
    await googleSignIn.signInSilently(suppressErrors: false);
  }

  handleSignin(GoogleSignInAccount accountDetail) async{
    if (accountDetail == null) {
      setState(() {
        _isAuth = false;
      });
      return;
    } else {
      await createUserInFireStore();
      setState(() {
        _isAuth = true;
      });
    }
  }

  createUserInFireStore() async {
    final user = googleSignIn.currentUser;
    print(user.email);
    var doc = await userRef.document(user.id).get();
    if (!doc.exists) {
      final userName = await Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => CreateAccount()),
      );
      await userRef.document(user.id).setData({
        "id": user.id,
        "userName": userName,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": DateTime.now()
      });
      await followersRef.document(user.id).collection("userFollowers").document(user.id).setData({});
      doc = await userRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  Future login() async {
    try {
      final accountDetail = await googleSignIn.signIn();

      handleSignin(accountDetail);
    } catch (error) {
      print("Error Signing In: $error");
    }
  }

  Scaffold buildUnauthScreen() {
    return Scaffold(
        body: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).accentColor
        ], begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            "InstaFlutter",
            style: TextStyle(
                fontFamily: "Signatra", fontSize: 90, color: Colors.white),
          ),
          GestureDetector(
              onTap: () {
                login();
              },
              child: Container(
                width: 260.0,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                      image:
                          AssetImage('assets/images/google_signin_button.png'),
                      fit: BoxFit.cover),
                ),
              ))
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return _isAuth ? buildAuthScreen() : buildUnauthScreen();
  }
}
