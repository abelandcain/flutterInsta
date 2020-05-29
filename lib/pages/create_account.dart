import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutterinstagram/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String _username;
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          key: _scaffoldKey,
          appBar: header(context,
              titleText: "Set up your profile", removeBackButton: true),
          body: ListView(
            children: <Widget>[
              Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 25),
                      child: Center(
                        child: Text(
                          "Create a username",
                          style: TextStyle(fontSize: 25),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(15),
                      child: Container(
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            onSaved: (val) {
                              _username = val;
                            },
                            autovalidate: true,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: "UserName",
                                labelStyle: TextStyle(fontSize: 15),
                                hintText: "Must be at least 3 characters"),
                            validator: (val) {
                              if (val.trim().length < 3 || val.isEmpty)
                                return 'UserName Too Short';
                              else if (val.trim().length > 12)
                                return "UserName Too Long";
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                    RaisedButton(
                      onPressed: () {
                        if (!_formKey.currentState.validate()) return;
                        _formKey.currentState.save();
                        SnackBar snackBar =
                            SnackBar(content: Text("Welcome $_username"));
                        _scaffoldKey.currentState.showSnackBar(snackBar);
                        Timer(Duration(seconds: 2), () {
                          Navigator.pop(context, _username);
                        });
                      },
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      color: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      child: Text(
                        "Submit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              )
            ],
          )),
    );
  }
}
