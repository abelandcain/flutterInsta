import 'package:cached_network_image/cached_network_image.dart';
import "package:flutter/material.dart";
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/widgets/progress.dart';
import "./home.dart";

class EditProfile extends StatefulWidget {
  final String currentUserId;

  const EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _displayNameValid = true;
  bool _bioValid = true;
  bool _isLoading;
  User user;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    getUser();
    super.initState();
  }

  getUser() async {
    setState(() {
      _isLoading = true;
    });
    final doc = await userRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    bioController.text = user.bio;
    displayNameController.text = user.displayName;
    setState(() {
      _isLoading = false;
    });
  }

  Column buildTextField(String label, controller) {
    String error;

    if (label.compareTo("Display name") == 0)
      error = _displayNameValid ? null : "Display Name too short";
    else
      error = _bioValid ? null : "Bio is too long";

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: controller,
          decoration:
              InputDecoration(hintText: "Update $label", errorText: error),
        )
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  updateProfileData(context) {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });

    if (_displayNameValid && _bioValid) {
      userRef.document(widget.currentUserId).updateData({
        "displayName": displayNameController.text,
        "bio": bioController.text
      });
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("Profile Updated")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            "Edit profile",
            style: TextStyle(color: Colors.black),
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.done,
                size: 30,
                color: Colors.green,
              ),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        body: _isLoading
            ? circularProgress()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: CircleAvatar(
                          backgroundImage:
                              CachedNetworkImageProvider(user.photoUrl),
                          radius: 60,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      buildTextField("Display name", displayNameController),
                      buildTextField("Bio", bioController),
                      SizedBox(height: 10),
                      RaisedButton(
                        onPressed: () => updateProfileData(context),
                        child: Text(
                          "Update Profile",
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: FlatButton.icon(
                            onPressed: () {},
                            color: Colors.grey[200],
                            icon: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              //size: 20,
                            ),
                            label: Text(
                              "Logout",
                              style: TextStyle(color: Colors.red, fontSize: 20),
                            )),
                      )
                    ],
                  ),
                ),
              ));
  }
}
