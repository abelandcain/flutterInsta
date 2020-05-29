import 'package:flutter/material.dart';
import 'package:flutterinstagram/pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutterinstagram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch:Colors.deepPurple,accentColor: Colors.teal,canvasColor: Colors.grey[100]),
      home:Home(),
    );
  }
}
