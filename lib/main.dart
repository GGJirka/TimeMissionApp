import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Language.dart';
import 'package:flutter_app/WifiState.dart';
import 'package:flutter_app/WorkRecords.dart';
import 'package:flutter_app/WorkState.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new MyHomePage(
        title: 'Time Mission',
        changeUser: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.changeUser}) : super(key: key);

  final String title;

  final bool changeUser;

  @override
  _MyHomePageState createState() =>
      new _MyHomePageState(changeUser: changeUser);
}

class _MyHomePageState extends State<MyHomePage> {

  /*KEY - HOLDS SCAFFOLD STATE*/
  final key = new GlobalKey<ScaffoldState>();

  final loginController = new TextEditingController();

  final passwordController = new TextEditingController();

  LoginActivity login;

  String loginUser, loginPass;

  bool _remember = true;

  bool changeUser;

  LanguageManager manager;

  _MyHomePageState({@required this.changeUser});

  @override
  void initState() {
    getPreferences();
    super.initState();
  }

  /*CHECKS IF USER IS ALREADY LOGGED IN*/
  getPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (sharedPreferences.getInt("numberOfUnfinishedWorks") != null) {
      if (sharedPreferences.getInt("numberOfUnfinishedWorks") > 0) {
        WifiState.instance.showNotification = true;
      }
    }

    manager = new LanguageManager(sharedPreferences: sharedPreferences);
    manager.setLanguage();

    if (sharedPreferences.getString('username') != "") {
      setState(() {
        loginUser = sharedPreferences.getString('username');
        loginPass = sharedPreferences.getString('password');
        loginController.text = loginUser;
        passwordController.text = loginPass;
        _remember = true;
      });
    }

    if (loginUser != "" &&
        loginUser != null &&
        loginPass != "" &&
        loginPass != null) {
      fetchPost(loginUser, loginPass);
    }
  }

  /*POST METHOD - CHECK FOR LOGIN*/
  fetchPost(String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    if (!changeUser) {
      showLoadingDialog();
    }
    var sharedCookie = sharedPreferences.getString("cookie");
    var connectivityResult = await (new Connectivity().checkConnectivity());

    /*CHECKS FOR INTERNET CONNECTION*/
    if (connectivityResult == ConnectivityResult.wifi) {
      var responseTest = await http.get(
          'https://tmtest.artin.cz/data/main/user',
          headers: {"cookie": sharedCookie});

      if (responseTest.statusCode == 401) {
        sharedPreferences.setString("cookie", "");
      }

      /*CHECK IF USER HAS ACTIVE COOKIE
      * IF SO THEN THE LOGIN IS NOT NEEDED*/
      if (sharedCookie == "" || sharedCookie == null) {
        var response = await http.post("https://tmtest.artin.cz/login", body: {
          "username": username,
          "password": password,
          "remember-me": "on"
        }, headers: {
          "content-type": "application/x-www-form-urlencoded"
        });

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        /*CHECK IF USERNAME AND PASSWORD ARE CORRECT*/
        if (response.statusCode != 500) {
          /*CORRECT*/
          var cookie = response.headers['set-cookie'];

          var responseTest2 = await http.get(
              'https://tmtest.artin.cz/data/main/user',
              headers: {"cookie": cookie});

          if (responseTest2.statusCode != 401) {
            if (_remember) {
              sharedPreferences.setString("cookie", cookie);
              sharedPreferences.setString('username', username);
              sharedPreferences.setString('password', password);
            }
            startWorkActivity(cookie);
          } else {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            myDialog(manager.getWords(16));
          }
        } else {
          /*INCORRECT*/
          myDialog(manager.getWords(17));
        }
      } else {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        startWorkActivity(sharedPreferences.getString("cookie"));
      }
    } else {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showToastMessage("No Internet connection");
    }
  }

  /*If login was successful, this starts the work activity*/
  void startWorkActivity(cookie) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    Navigator.pushReplacement(
        context,
        new MaterialPageRoute(
            builder: (context) =>
            new WorkActivity(cookie: cookie, manager: manager)));
  }

  /*Dialog with custom text*/
  Future myDialog(text) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return new AlertDialog(
          content: new Text(text),
        );
      },
    );
  }

  /*shows loading dialog.*/
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      child: new Dialog(
        child: new Padding(
          padding: new EdgeInsets.only(
              top: 20.0, bottom: 20.0, right: 0.0, left: 0.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new CircularProgressIndicator(),
              new Divider(
                height: 20.0,
                color: Colors.white,
              ),
              new Text(
                "Loading",
                style: new TextStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _rememberChange(bool value) {
    setState(() {
      _remember = value;
    });
  }

  void showToastMessage(String message) {
    key.currentState.showSnackBar(new SnackBar(
      content: new Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: this.key,
      appBar: new AppBar(
        centerTitle: true,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      //UI for login
      body: new Container(
          child: new Center(
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new FractionallySizedBox(
                  widthFactor: 0.7, // 265 / 375
                  child: new Container(
                    child: new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new Theme(
                          data: new ThemeData(
                            primaryColor: Colors.orange[700],
                            hintColor: Colors.black,
                            //textSelectionColor: Colors.orange[700],
                          ),
                          child: new TextField(
                            decoration: new InputDecoration(
                              labelText: "Username", //.getWords(19)
                            ),
                            controller: loginController,
                          ),
                        ),
                        new Theme(
                          data: new ThemeData(
                            primaryColor: Colors.orange[700],
                            hintColor: Colors.black,
                            //textSelectionColor: Colors.orange[700],
                          ),
                          child: new TextField(
                            obscureText: true,
                            decoration: new InputDecoration(
                              labelText: "password",
                            ),
                            controller: passwordController,
                          ),
                        ),
                        new Divider(
                          height: 5.0,
                          color: Colors.white,
                        ),
                        new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                new Checkbox(
                                    value: _remember,
                                    onChanged: (bool value) {
                                  _rememberChange(value);
                                }),
                                new Text(/*manager.getWords(21)*/
                                    "Remember me"),
                              ],
                            ),
                          ],
                        ),
                        new Divider(
                          height: 15.0,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                new FractionallySizedBox(
                  widthFactor: 0.7,
                  child: new Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      new RaisedButton(
                        child: Text(/*manager.getWords(22)*/ "Login"),
                        color: Colors.orange[700],
                        splashColor: Colors.orangeAccent,
                        textColor: Colors.white,
                        elevation: 0.0,
                        onPressed: () {
                          fetchPost(
                              loginController.text, passwordController.text);
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          )),
    );
  }
}
