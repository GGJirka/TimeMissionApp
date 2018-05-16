import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/Settings.dart';
import 'package:flutter_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginActivity extends StatelessWidget{
  String username;
  String password;
  String cookie;
  bool _isChecked;

  LoginActivity(String user, String pass, String cook){
    username = user;
    password = pass;
    cookie = cook;
  }

  saveLogin() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('username', username);
    sharedPreferences.setString('password', password);
  }

  /*Save user to preferences and does auto login next time*/
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: new LoginStateful(title: 'TimeMission', cookie: cookie,),
    );
  }
}

class LoginStateful extends StatefulWidget {
  LoginStateful({Key key, this.title, this.cookie}) : super(key: key);

  final String title;

  final String cookie;

  @override
  _LoginState createState() => new _LoginState(cookie: cookie);
}

class _LoginState extends State<LoginStateful> {
  bool _isChecked = false;
  String _timeArrived = "";
  String _timeLeft = "";
  String user = "";
  String cookie;

  List<ListItem> projects = new List();
  _LoginState({this.cookie});

  void changeChecked(bool checked){
    setState((){
      var time =  new DateTime.now();
      _isChecked = checked;

      if(checked) {
        _timeArrived = 'Time arrived: ' + time.hour.toString() + ':' + time.minute.toString() + ':' + time.second.toString();
        saveWorkState(_isChecked, _timeArrived, _timeLeft);
        _timeLeft = "";
      }else{
        _timeLeft = 'Time left: ' + time.hour.toString() + ':' + time.minute.toString() + ':' + time.second.toString();
        saveWorkState(_isChecked, _timeArrived, _timeLeft);
      }
    });
  }

  @override
  void initState(){
    super.initState();
    initUser();
  }


  saveWorkState(bool state, String _timeArrived, String _timeLeft) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setBool('isInWork', state);
    sharedPreferences.setString('timeArrived', _timeArrived);
    sharedPreferences.setString('timeLeft', _timeLeft);
  }

  initUser() async{

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      user = sharedPreferences.getString('username');
      if(sharedPreferences.getBool('isInWork') != null && sharedPreferences.getString('timeArrived') != null && sharedPreferences.getString('timeLeft') != null){
        _isChecked = sharedPreferences.getBool('isInWork');
        _timeArrived = sharedPreferences.getString('timeArrived');
        if(_isChecked){
          _timeLeft = "";
        }else {
          _timeLeft = sharedPreferences.getString('timeLeft');
        }
      }
    });
    print("COOKIE: " + cookie);
    var requestResponse =  await http.get('https://tmtest.artin.cz/data/work-records?filter={"dateFrom":"2018-05-14","dateTo":"2018-05-20","userId":205}'
        ,headers: {"cookie" : cookie});

    print(requestResponse.body);

    List data  = json.decode(requestResponse.body);
    if (data != null) {
      for (int i = 0; i < data.length; i++) {
        setState(() {
          projects.add(new ListItem(date: data[i]['hours'].toString(), time: data[i]['dateFrom'].toString(),timeTo: data[i]['dateTo'].toString(), project: data[i]['projectName'], hour: data[i]['hours'].toString()
              ,workType: data[i]['hours'].toString(), workDes: data[i]['hours'].toString(), note: data[i]['hours'].toString()));
        });
      }
    }
  }

  logout() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
    Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) =>
        new MyApp()));
  }

  void openSettings(){
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) =>
        new SettingsHome()));
  }

  @override
  Widget build(BuildContext context){

    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),

        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.settings), onPressed: openSettings,)
        ],
      ),
      body: new Padding(padding: new EdgeInsets.all(16.0),
        child: new ListView(
          children: projects.map((ListItem item){
            return new Column(
              children: <Widget>[
                new Row(
                  children: <Widget>[
                    new Text(item.date),
                    new Text(" hours"),
                  ],
                ),
                new Row(
                  children: <Widget>[
                    new Text("Project: "),
                    new Text(item.project),
                  ],
                ),
                new Row(
                  children: <Widget>[
                    new Text("Date from: "),
                    new Text(item.time),
                  ],
                ),
                new Row(
                  children: <Widget>[
                    new Text("Date to: "),
                    new Text(item.timeTo),
                  ],
                ),
                new Divider(
                  height: 10.0, color: Colors.white,
                )
              ],
            );
          }).toList(),
        ),
      ),
        floatingActionButton: new FloatingActionButton(
          tooltip: 'Add new weight entry',
          child: new Icon(Icons.add),
        ),
      );

  }
}


class ListItem{
  String date;
  String time;
  String timeTo;
  String project;
  String hour;
  String workType;
  String workDes;
  String note;

  ListItem({this.date, this.time, this.timeTo, this.project, this.hour, this.workType, this.workDes, this.note});
}

