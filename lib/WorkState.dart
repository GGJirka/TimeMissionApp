import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/Language.dart';
import 'package:flutter_app/Settings.dart';
import 'package:flutter_app/WifiState.dart';
import 'package:flutter_app/WorkRecords.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/*
* TODO  Fix the time at :55
*/
class WorkActivity extends StatelessWidget {
  final String cookie;
  final LanguageManager manager;

  WorkActivity({this.cookie, this.manager});

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new WorkPage(
        title: 'Time Mission',
        cookie: cookie,
        manager: manager,
      ),
    );
  }
}

class WorkPage extends StatefulWidget {
  WorkPage({Key key, this.title, this.cookie, this.manager}) : super(key: key);

  final String title;
  final String cookie;
  final LanguageManager manager;

  @override
  _WorkPageState createState() =>
      new _WorkPageState(cookie: cookie, manager: manager);
}

class _WorkPageState extends State<WorkPage> {
  /*Native platform to get SSID from java code*/
  static const platform = const MethodChannel('artin.timemission/ssid');

  final key = new GlobalKey<ScaffoldState>();

  final descriptionController = new TextEditingController();
  LanguageManager manager;

  List<Project> projects = new List();
  List<String> projectNames = ["test", "test"];
  List<String> workTypes = ["test", "test"];
  List<Project> works = new List();

  bool state = false;
  bool init = false;
  String text = "";
  String timeStarted = "";
  String buttonState = "";
  String cookie;
  String projectName;
  String workType;

  //String SSIDState = "LISTEN";

  int userId;
  var countdown = 0;

  _WorkPageState({this.cookie, this.manager});

  @override
  void initState() {
    buttonState = manager.getWords(0);
    text = manager.getWords(2);
    _initState();
    super.initState();
  }

  _onWorkTypeChange(String value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("workType", value);
    setState(() {
      workType = value;
    });
  }

  void openMenu() {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) =>
        new LoginStateful(
          title: 'Work Records',
          cookie: cookie,
          manager: manager,
        )));
  }

  void openSettings() {
    Navigator.of(context).push(new MaterialPageRoute(
        builder: (context) =>
        new SettingsHome(
          title: 'Settings',
          manager: manager,
        )));
  }

  void _onChange(String value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("projectName", value);
    int id;
    setState(() {
      projectName = value;

      for (int i = 0; i < projects.length; i++) {
        if (projectName == projects[i].projectName) {
          id = projects[i].projectId;
        }
      }
    });

    var response2 = await http.get(
        'https://tmtest.artin.cz/data/projects/$id/work-types',
        headers: {"cookie": cookie});

    List workData = json.decode(response2.body);

    setState(() {
      workTypes.clear();
      for (int j = 0; j < workData.length; j++) {
        workTypes.add(workData[j]['name'].toString());
        works.add(new Project(
            projectName: workData[j]['name'], projectId: workData[j]['id']));
      }

      if (workTypes.contains(sharedPreferences.getString("workType"))) {
        workType = sharedPreferences.getString("workType");
      } else {
        workType = workTypes.first;
      }
      //sharedPreferences.setString("workType", workType);
    });
  }

  /*INIT STATE*/
  _initState() async {
    getSSID();
    projectNames.clear();
    workTypes.clear();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    try {
      var response = await http.get('https://tmtest.artin.cz/data/main/user',
          headers: {"cookie": cookie});
      userId = json.decode(response.body)['user']['id'];

      var response3 = await http.get(
          'https://tmtest.artin.cz/data/projects/most-frequent-and-assigned-of-user',
          headers: {"cookie": cookie});
      List availableProjects = json.decode(response3.body);

      for (int j = 0; j < availableProjects.length; j++) {
        projects.add(new Project(
            projectName: availableProjects[j]['name'],
            projectId: availableProjects[j]['id']));
        projectNames.add(availableProjects[j]['name']);
      }

      int id = projects[0].projectId;

      var response2 = await http.get(
          'https://tmtest.artin.cz/data/projects/$id/work-types',
          headers: {"cookie": cookie});

      if (sharedPreferences.getString("projectName") != "" &&
          sharedPreferences.getString("projectName") != null) {
        projectName = sharedPreferences.getString("projectName");
        _onChange(projectName);
      } else {
        projectName = projectNames.first;
      }

      List workData = json.decode(response2.body);

      for (int j = 0; j < workData.length; j++) {
        workTypes.add(workData[j]['name'].toString());
        works.add(new Project(
            projectName: workData[j]['name'], projectId: workData[j]['id']));
      }
      if (workTypes.length != 0) {
        workType = workTypes.first;
      }
    } catch (e) {}

    setState(() {
      if (sharedPreferences.getString("timeFrom") != "" &&
          sharedPreferences.getString("timeFrom") != null) {
        state = true;
        buttonState = manager.getWords(1);
        timeStarted = manager.getWords(3) +
            sharedPreferences.getString("timeFrom").substring(10, 16);
        text = "";
      } else {
        timeStarted = "";
        buttonState = manager.getWords(0);
        state = false;
      }
      init = true;
    });
  }

  _saveTime(bool pressedByWifi) async {
    /*if(!state){
      WifiState.instance.STATE = "INITIALIZE";
    }else{
      WifiState.instance.STATE = "LISTEN";
    }*/
    String now = new DateTime.now().toString();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String dateFrom;
    setState(() {
      if (!state) {
        buttonState = manager.getWords(1);
        text = "";
        state = true;
      } else {
        dateFrom = sharedPreferences.getString("timeFrom");
        setTime(dateFrom, pressedByWifi);
      }
      if (state) {
        sharedPreferences.setString("timeFrom", now);
        timeStarted = manager.getWords(3) + now.substring(10, 16);
      } else {
        print(sharedPreferences.getString("timeFrom"));
        dateFrom = sharedPreferences.getString("timeFrom");
        sharedPreferences.setString("timeFrom", "");
      }
    });

    if (!state) {
      setTime(dateFrom, pressedByWifi);
    }
  }

  void setTime(dateFrom, bool pressedByWifi) async {
    String fDateTo;
    String fDateFrom;

    print(dateFrom);

    if (getMinutes(dateFrom) == 60) {
      print(dateFrom.substring(11, 13));

      fDateFrom = dateFrom.substring(0, 10) +
          "T" +
          (int.parse(dateFrom.substring(11, 13)) + 1).toString() +
          ":00:00+03:00";
    } else {
      fDateFrom = dateFrom.substring(0, 10) +
          "T" +
          dateFrom.substring(11, 14) +
          getMinutes(dateFrom).toString() +
          ":00+02:00";
    }

    var dateTo;

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("timeTo") != "" &&
        sharedPreferences.getString("timeTo") != null) {
      dateTo = sharedPreferences.getString("timeTo");
    } else {
      dateTo = new DateTime.now().toIso8601String();
    }

    if (getMinutes(dateTo) == 60) {
      fDateTo = dateTo.substring(0, 10) +
          "T" +
          (int.parse(dateTo.substring(11, 13)) + 1).toString() +
          ":00:00+03:00";
    } else {
      fDateTo = dateTo.substring(0, 10) +
          "T" +
          dateTo.substring(11, 14) +
          getMinutes(dateTo).toString() +
          ":00+02:00";
    }

    /*-------------------------------------------------------*/
    List<String> workData = new List<String>();

    workData.add(474191.toString());
    workData.add(projectName);
    workData.add(getProjectId(projectName).toString());
    workData.add(workType);
    workData.add(userId.toString());
    workData.add(getWorkId(workType).toString());
    workData.add(getProjectId(projectName).toString());
    workData.add(fDateFrom);
    workData.add(fDateTo);

    print(fDateFrom);
    print(fDateTo);
    if (sharedPreferences.getInt("numberOfUnfinishedWorks") == null) {
      sharedPreferences.setInt("numberOfUnfinishedWorks", 0);
    }

    /*if (int.parse(fDateTo.substring(11, 13)) -
                int.parse(fDateFrom.substring(11, 13)) >
            0 ||
        int.parse(fDateFrom.substring(14, 16)) -
                int.parse(fDateTo.substring(14, 16)) >
            0) {*/

    sharedPreferences.setInt("numberOfUnfinishedWorks",
        sharedPreferences.getInt("numberOfUnfinishedWorks") + 1);
    String prefName = "unfinishedWork" +
        sharedPreferences.getInt("numberOfUnfinishedWorks").toString();
    sharedPreferences.setStringList(prefName, workData);
    print(prefName);
    /* } else {
      showToastMessage("Work time must be longer than 10 min");
    }*/

    WifiState.instance.showNotification = true;
    setState(() {
      state = false;
      buttonState = manager.getWords(0);
      text = manager.getWords(2);
      sharedPreferences.setString("timeFrom", "");
      sharedPreferences.setString("timeTo", "");
      if (pressedByWifi) {
        WifiState.instance.STATE = "LISTEN";
      }
    });
    /*-------------------------------------------------------*/
  }

  void showToastMessage(String message) {
    key.currentState.showSnackBar(new SnackBar(
      content: new Text(message),
    ));
  }

  int getMinutes(String word) {
    int min = int.parse(word.substring(15, 16));
    int minutes = int.parse(word.substring(14, 16));

    if (min >= 5) {
      minutes = minutes + (10 - min);
    } else {
      minutes = minutes - min;
    }
    return minutes;
  }

  double getExactHour(String time, String time2) {
    return double.parse(
        (int.parse(time.substring(11, 13)) - int.parse(time2.substring(11, 13)))
            .toString() +
            "." +
            (1 / (60 / (getMinutes(time) - getMinutes(time2))))
                .toString()
                .substring(2, 3));
  }

  /*Auto start work based on WiFi*/
  Future<String> getSSID() async {
    String SSID;
    try {
      SSID = await platform.invokeMethod("getSSID");
      var state = WifiState.instance.STATE;
      switch (state) {
        case "LISTEN":
          if (SSID == '"artin_unifi_guest"') {
            WifiState.instance.STATE = "INITIALIZE";
          }
          break;

        case "INITIALIZE":
          await _startOnWifi();
          break;

        case "SAVE":
          if (SSID == "<unknown ssid>") {
            this.state ? await _saveDataOnWifiEnd() : WifiState.instance.STATE =
            "LISTEN";
          }
          break;
      }
    } catch (exception) {
      print(exception);
    }
    getSSID();
    return SSID;
  }

  _saveDataOnWifiEnd() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("timeTo", new DateTime.now().toString());
    print(sharedPreferences.getString("timeFrom"));
    print(sharedPreferences.getString("timeTo"));
    setTime(sharedPreferences.getString("timeFrom"), true);
  }

  _startOnWifi() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.getString("timeFrom") == "") {
      sharedPreferences.setString("timeFrom", new DateTime.now().toString());
      print(sharedPreferences.getString("timeFrom"));
      setState(() {
        state = true;
        buttonState = manager.getWords(1);
        timeStarted = manager.getWords(3) +
            sharedPreferences.getString("timeFrom").substring(10, 16);
        text = "";
      });
    }
    WifiState.instance.STATE = "SAVE";
  }

  Future sleep1() {
    return new Future.delayed(const Duration(seconds: 1), () => "1");
  }

  int getProjectId(String name) {
    for (int i = 0; i < projects.length; i++) {
      if (name == projects[i].projectName) {
        return projects[i].projectId;
      }
    }
  }

  int getWorkId(String name) {
    for (int i = 0; i < works.length; i++) {
      print(works[i].projectName);
      if (name == works[i].projectName) {
        return works[i].projectId;
      }
    }
  }

  Icon getMenuIcon() {
    if (WifiState.instance.showNotification) {
      return new Icon(Icons.notifications);
    } else {
      return new Icon(Icons.notifications_none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
      child: new Scaffold(
          key: key,
          appBar: new AppBar(
            title: new Text(widget.title),
            actions: <Widget>[
              new IconButton(
                icon: new Icon(Icons.settings),
                tooltip: manager.getWords(6),
                onPressed: openSettings,
              ),
              new IconButton(
                icon: getMenuIcon(),
                tooltip: manager.getWords(7),
                onPressed: openMenu,
              ),
              new IconButton(
                icon: new Icon(Icons.exit_to_app),
                tooltip: manager.getWords(8),
                onPressed: () => exit(0),
              )
            ],
          ),
          body: new Container(
            child: new Center(
              child: new Opacity(
                opacity: init ? 1.0 : 0.0,
                child: new FractionallySizedBox(
                  widthFactor: 0.7,
                  child: new Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      new Opacity(
                        opacity: state ? 1.0 : 0.0,
                        child: new Text(
                          timeStarted,
                          textScaleFactor: 1.1,
                          style: new TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      new Divider(height: 15.0, color: Colors.white),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          new RaisedButton(
                            child: new Padding(
                              child: new Text(
                                /*state == null ? "ahoj" : (state == true ? "1":"2")*/
                                "$buttonState",
                                style: new TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                textScaleFactor: 1.2,
                              ),
                              padding: new EdgeInsets.all(15.0),
                            ),
                            color: Colors.orange[800],
                            splashColor: Colors.orangeAccent,
                            textColor: Colors.white,
                            elevation: 4.0,
                            onPressed: () {
                              _saveTime(false);
                            },
                          ),
                        ],
                      ),
                      new Divider(
                        height: 20.0,
                        color: Colors.white,
                      ),
                      new Opacity(
                        opacity: state ? 0.0 : 1.0,
                        child: new Text(
                          text,
                          style: new TextStyle(
                              color: Colors.black.withOpacity(0.3)),
                        ),
                      ),
                      new Opacity(
                        opacity: state ? 1.0 : 0.0,
                        child: new IgnorePointer(
                          ignoring: !state,
                          child: new Column(
                          children: <Widget>[
                            new Row(
                              children: <Widget>[
                                new Text(
                                  manager.getWords(4),
                                  style: new TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.left,
                                  textScaleFactor: 1.1,
                                ),
                              ],
                            ),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new DropdownButton(
                                    onChanged: (String value) {
                                      _onChange(value);
                                    },
                                    value: projectName,
                                    items: projectNames
                                        .toList()
                                        .map((String value) {
                                      return new DropdownMenuItem(
                                        value: value,
                                        child: new Container(
                                          child: new Text(value),
                                          width: 200.0,
                                        ),
                                        //200.0 to 100.0
                                      );
                                    }).toList())
                              ],
                            ),
                            new Divider(
                              height: 20.0,
                              color: Colors.white,
                            ),
                            new Row(
                              children: <Widget>[
                                new Text(
                                  manager.getWords(5),
                                  style: new TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.left,
                                  textScaleFactor: 1.1,
                                ),
                              ],
                            ),
                            new Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                new DropdownButton(
                                    onChanged: (String value) {
                                      _onWorkTypeChange(value);
                                    },
                                    value: workType,
                                    items:
                                    workTypes.toList().map((String value) {
                                      return new DropdownMenuItem(
                                        value: value,
                                        child: new Container(
                                          child: new Text(value),
                                          width: 200.0,
                                        ),
                                        //200.0 to 100.0
                                      );
                                    }).toList())
                              ],
                            ),
                          ],
                        ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )),
    );
  }
}

class Project {
  String projectName;

  int projectId;

  Project({this.projectName, this.projectId});
}
