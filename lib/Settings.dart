import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/Language.dart';
import 'package:flutter_app/WifiState.dart';
import 'package:flutter_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/*
* TODO - Popup the dialog on new login
*/

class SettingsHome extends StatefulWidget {
  SettingsHome({Key key, this.title, this.manager}) : super(key: key);

  final String title;

  final LanguageManager manager;

  @override
  SettingsHomeState createState() => new SettingsHomeState(manager: manager);
}

class SettingsHomeState extends State<SettingsHome> {
  static const platform = const MethodChannel('artin.timemission/ssid');

  int groupValue;

  bool _state = true;

  bool wifiTracking;

  LanguageManager manager;

  Controllers controllers = new Controllers();

  SettingsHomeState({this.manager});

  List<ExpansionItem> listItems;
  List<ExpansionItem> listItems2;
  List<ExpansionItem> listItems3;


  @override
  void initState() {
    super.initState();
    listItems = <ExpansionItem>[
      new ExpansionItem(
          isExpanded: true,
          names: <String>[manager.getWords(10), manager.getWords(11)]),
    ];
    listItems2 = <ExpansionItem>[
      new ExpansionItem(
          isExpanded: false,
          names: <String>[manager.getWords(10), manager.getWords(11)]),
    ];
    listItems3 = <ExpansionItem>[
      new ExpansionItem(
          isExpanded: false,
          names: <String>[manager.getWords(10), manager.getWords(11)]),
    ];
    loadValue();
  }

  loadValue() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.get("language") == "czech"
        ? changeValue(1, true)
        : changeValue(0, true);

    if(sharedPreferences.getBool("Tracking") != null) {
      wifiTracking = sharedPreferences.getBool("Tracking");
    }else{
      wifiTracking = true;
    }
  }

  void changeValue(int value, bool isFromInit) {
    setState(() {
      groupValue = value == 0 ? 0 : 1;
      if (!isFromInit) {
        saveValue(value);
      }
    });
  }

   onChange(bool value) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      wifiTracking = value;
    });

    sharedPreferences.setBool("Tracking", wifiTracking);
    print(sharedPreferences.getBool("Tracking"));
  }

  void changeState() {
    _state == _state ? false : true;
  }

  void changeWifiState(bool value) {
    setState(() {
      _state = value;
    });
  }

  saveValue(int value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    value == 0
        ? sharedPreferences.setString("language", "english")
        : sharedPreferences.setString("language", "czech");

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return new AlertDialog(
          content: new Text(manager.getWords(29)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(manager.getWords(6))),
      body: new ListView(
        children: <Widget>[
          new ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                listItems[index].isExpanded = !listItems[index].isExpanded;
                listItems2[index].isExpanded = false;
                listItems3[index].isExpanded = false;
              });
            },
            children: listItems.map((ExpansionItem item) {
              return new ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return new Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
                    child: new Text(
                      manager.getWords(9),
                      textScaleFactor: 1.1,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
                isExpanded: item.isExpanded,
                body: new Column(
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new Radio(
                          value: 0,
                          groupValue: groupValue,
                          onChanged: (int v) => changeValue(v, false),
                        ),
                        new Padding(
                          padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                          child: new Text(item.names[0]),
                        ),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new Radio(
                          value: 1,
                          groupValue: groupValue,
                          onChanged: (int v) => changeValue(v, false),
                        ),
                        new Padding(
                          padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                          child: new Text(item.names[1]),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          new ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                listItems2[index].isExpanded = !listItems2[index].isExpanded;
                listItems[index].isExpanded = false;
                listItems3[index].isExpanded = false;
              });
            },
            children: listItems2.map((ExpansionItem item) {
              return new ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return new Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
                    child: new Text(
                      manager.getWords(30),
                      textScaleFactor: 1.1,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
                isExpanded: item.isExpanded,
                body: new FractionallySizedBox(
                  widthFactor: 0.7,
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
                          controller: controllers.getLoginController(),
                          decoration: new InputDecoration(
                            labelText: manager.getWords(19), //.getWords(19)
                          ),
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
                          controller: controllers.getPasswordController(),
                          decoration: new InputDecoration(
                            labelText: manager.getWords(20),
                          ),
                        ),
                      ),
                      new Divider(
                        height: 5.0,
                        color: Colors.white,
                      ),
                      new Divider(
                        height: 15.0,
                        color: Colors.white,
                      ),
                      new FractionallySizedBox(
                        widthFactor: 0.7,
                        child: new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new RaisedButton(
                              child: Text(manager.getWords(22)),
                              color: Colors.orange[700],
                              splashColor: Colors.orangeAccent,
                              textColor: Colors.white,
                              elevation: 0.0,
                              onPressed: () {
                                newLogin();
                              },
                            ),
                            new Divider(
                              height: 15.0,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          new ExpansionPanelList(
            expansionCallback: (int index, bool isExpanded) {
              setState(() {
                listItems3[index].isExpanded = !listItems3[index].isExpanded;
                listItems2[index].isExpanded = false;
                listItems[index].isExpanded = false;
              });
            },
            children: listItems3.map((ExpansionItem item) {
              return new ExpansionPanel(
                headerBuilder: (BuildContext context, bool isExpanded) {
                  return new Padding(
                    padding: EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 15.0),
                    child: new Text(
                      "WiFi tracking",
                      textScaleFactor: 1.1,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
                isExpanded: item.isExpanded,
                body: new Column(
                  children: <Widget>[
                    new Row(
                      children: <Widget>[
                        new Checkbox(value: wifiTracking, onChanged: (bool value){onChange(value);}),
                        new Padding(
                          padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                          child: new Text("WiFi tracking"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  newLogin() async {
    //try{
    var response = await http.post("https://tmtest.artin.cz/login", body: {
      "username": controllers
          .getLoginController()
          .text,
      "password": controllers
          .getPasswordController()
          .text,
      "remember-me": "on"
    }, headers: {
      "content-type": "application/x-www-form-urlencoded"
    });

    var cookie = response.headers['set-cookie'];

    var auth = await http.get('https://tmtest.artin.cz/data/main/user',
        headers: {"cookie": cookie});

    if (auth.statusCode != 401) {
      checkForUnfinishedProjects(cookie);
    } else {
      myDialog("Something went wrong");
    }

    print(response.statusCode);
    print(response.body);

    /*}catch(exception){
      print(exception);
    }*/
  }

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

  checkForUnfinishedProjects(cookie) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();


    if (sharedPreferences.getInt("numberOfUnfinishedWorks") > 0) {
      unfinishedTaskDialog(cookie);
    } else {
      saveCredentials(cookie);
    }
  }

  saveCredentials(cookie) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    sharedPreferences.setString("timeFrom", "");

    /*for (int i = 0; i < sharedPreferences.getInt("numberOfUnfinishedWorks"); i++) {
      String prefName = "unfinishedWork" + i.toString();
      sharedPreferences.setStringList(prefName, null);
    }*/

    WifiState.instance.showNotification = false;
    sharedPreferences.setString("cookie", cookie);
    sharedPreferences.setString(
        'username', controllers
        .getLoginController()
        .text);
    sharedPreferences.setString(
        'password', controllers
        .getPasswordController()
        .text);

    Navigator.pushReplacement(
        context, new MaterialPageRoute(builder: (context) =>
    new MyHomePage(
      title: "Time Mission", changeUser: true,)));
  }

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
              new Divider(height: 20.0, color: Colors.white,),
              new Text("Loading", style: new TextStyle(
              ),),
            ],
          ),
        ),
      ),
    );
  }

  Future<Null> unfinishedTaskDialog(cookie) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text("Waiting for upload"),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(
                    "You have project waiting to upload. Would you like to continue anyway?"),
              ],
            ),
          ),

          actions: <Widget>[
            new FlatButton(
              child: new Text(
                "Cancel",
                textScaleFactor: 1.1,
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            new FlatButton(
              child: new Text(
                "Continue",
                textScaleFactor: 1.1,
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.pop(context);
                saveCredentials(cookie);
              },
            ),
          ],
        );
      },
    );
  }
}

/*class that holds item data in expansion list*/
class ExpansionItem {
  bool isExpanded;

  final List<String> names;

  ExpansionItem({this.isExpanded, this.names});
}

/*Controller handlers for login and password*/
class Controllers {
  final login = new TextEditingController();
  final password = new TextEditingController();

  TextEditingController getLoginController() {
    return login;
  }

  TextEditingController getPasswordController() {
    return password;
  }
}
