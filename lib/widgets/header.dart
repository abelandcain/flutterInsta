import 'package:flutter/material.dart';

AppBar header(context,
    {bool isAppTitle = false,
    String titleText,
    bool removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: !removeBackButton,
    title: Text(
      isAppTitle ? "InstaFlutter" : titleText,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
          color: Colors.white,
          fontFamily: isAppTitle ? "Signatra" : "",
          fontSize: isAppTitle ? 50 : 22),
    ),
    centerTitle: true,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).accentColor
            ]),
      ),
    ),
  );
}
