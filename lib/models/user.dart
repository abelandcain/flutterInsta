import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id, userName, email, photoUrl, displayName, bio;

  User(
      {this.id,
      this.userName,
      this.email,
      this.photoUrl,
      this.displayName,
      this.bio});

  factory User.fromDocument(DocumentSnapshot doc) {
    return User(
        id: doc["id"],
        email: doc["email"],
        userName: doc["userName"],
        photoUrl: doc["photoUrl"],
        displayName: doc["displayName"],
        bio: doc["bio"]);
  }
}
