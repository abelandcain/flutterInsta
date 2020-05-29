import 'dart:io';
import 'package:geolocator/geolocator.dart';

import "./home.dart";
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutterinstagram/models/user.dart';
import 'package:flutterinstagram/widgets/progress.dart';
import 'package:image/image.dart' as Im;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  final locationController = TextEditingController();
  final captionController = TextEditingController();
  String completeAddress;
  File file;
  bool isUploading = false;
  String postId = Uuid().v4();
  void _handleimage(ImageSource source) async {
    Navigator.pop(context);
    File file = await ImagePicker.pickImage(
      source: source,
      maxHeight: 675,
      maxWidth: 960,
    );
    setState(() {
      this.file = file;
    });
  }

  Future<String> uploadImage(imageFile) async {
    final uploadTask = storageRef.child("post_$postId.jpg").putFile(imageFile);
    final storageSnap = await uploadTask.onComplete;
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  getUserLocation() async {
    final position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    final placemark = placemarks[0];
    completeAddress =
        '${placemark.subThoroughfare} ${placemark.thoroughfare}, ${placemark.subLocality} ${placemark.locality}, ${placemark.subAdministrativeArea}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}';
    String formattedAddress = "${placemark.locality}, ${placemark.country}";
    locationController.text = formattedAddress;
  }

  createPostInFirestore(
      {@required String mediaUrl,
      @required String location,
      @required String caption}) {
    postRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "userName": widget.currentUser.userName,
      "mediaUrl": mediaUrl,
      "location": location,
      "timestamp": DateTime.now(),
      "likes": [],
      "description": caption,
      "completeAddress": completeAddress
    });
    captionController.clear();
    locationController.clear();

    setState(() {
      file = null;
      isUploading = false;
      postId = Uuid().v4();
    });
  }

  handleSubmit() async {
    setState(() {
      isUploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(file);
    createPostInFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        caption: captionController.text);
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImageFile = File('$path/image_$postId.jpg')
      ..writeAsBytesSync(
        Im.encodeJpg(imageFile, quality: 85),
      );
    setState(() {
      file = compressedImageFile;
    });
  }

  selectImage(BuildContext context) {
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text("Create Post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Photo with Camera"),
                onPressed: () => _handleimage(ImageSource.camera),
              ),
              SimpleDialogOption(
                child: Text("Photo from Gallery"),
                onPressed: () => _handleimage(ImageSource.gallery),
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.of(ctx).pop(),
              )
            ],
          );
        });
  }

  Container buildSplashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset("assets/images/upload.svg", height: 260),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: RaisedButton(
                onPressed: () => selectImage(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Upload Image",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                  ),
                ),
                color: Colors.deepOrange),
          )
        ],
      ),
    );
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              file = null;
            });
          },
          color: Colors.black,
        ),
        title: Text(
          "Create Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          FlatButton(
            onPressed: isUploading ? null : () => handleSubmit(),
            child: Text(
              "Post",
              style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          isUploading ? linearProgress() : Text(""),
          Container(
            height: 220,
            width: double.infinity,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                        image: FileImage(file), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Write a caption...",
                    border: InputBorder.none,
                  ),
                  controller: captionController,
                )),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop, color: Colors.orange, size: 35),
            title: Container(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Where was this photo taken",
                    border: InputBorder.none,
                  ),
                  controller: locationController,
                )),
          ),
          Container(
            width: 200,
            height: 200,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: getUserLocation,
              color: Colors.blue,
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          )
        ],
      ),
    );
  }
bool get wantKeepAlive=>true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
