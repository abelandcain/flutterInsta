import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/pages/home.dart';
import 'package:flutterinstagram/pages/profile.dart';
import 'package:flutterinstagram/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final searchController = TextEditingController();
  Future<QuerySnapshot> searchResult;
  handleSearch(String query) {
    var users = userRef
        .where("displayName", isGreaterThanOrEqualTo: query.toUpperCase())
        .getDocuments();
    setState(() {
      searchResult = users;
    });
  }

  Container buildNoContent() {
    final orientation = MediaQuery.of(context).orientation;
    return Container(
      alignment: Alignment.center,
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SvgPicture.asset("assets/images/search.svg",
                height: orientation == Orientation.landscape ? 200 : 300),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 60,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic),
            )
          ],
        ),
      ),
    );
  }

  AppBar buildSearchField() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          filled: true,
          hintText: "Search for a user....",
          prefixIcon: Icon(
            Icons.account_box,
            size: 28.0,
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear, size: 28),
            onPressed: () => searchController.clear(),
          ),
        ),
        onFieldSubmitted: handleSearch,
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return circularProgress();
          QuerySnapshot data = snapshot.data;
          return ListView.builder(
            itemBuilder: (ctx, i) {
              User user = User.fromDocument(data.documents[i]);
              return UserResult(user);
            },
            itemCount: data.documents.length,
          );
        },
        future: searchResult);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildSearchField(),
      body: searchResult == null ? buildNoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  const UserResult(this.user);
  showProfile(context, {profileId}) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => Profile(profileId: profileId)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.3),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => showProfile(context,profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey,
              ),
              title: Text(
                user.displayName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                user.userName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Divider(
            height: 2.0,
            color: Colors.black87,
          )
        ],
      ),
    );
  }
}
