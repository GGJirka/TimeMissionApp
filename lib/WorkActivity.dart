import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/LoginActivity.dart';
import 'package:flutter_app/Settings.dart';
import 'package:flutter_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class WorkActivity extends StatelessWidget {
  final String cookie;

  WorkActivity({this.cookie});

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: new WorkPage(title: 'TimeMission',cookie: cookie,),
    );
  }
}

class WorkPage extends StatefulWidget {
  WorkPage({Key key, this.title, this.cookie}) : super(key: key);

  final String title;
  final String cookie;

  @override
  _WorkPageState createState() => new _WorkPageState(cookie: cookie);
}

class _WorkPageState extends State<WorkPage> {
  int counter = 0;
  bool state = false;
  bool init = false;
  String timeStarted = "";
  String buttonState = "Start working";
  String cookie;
  String projectName;
  String workType;
  int userId;
  List<Project> projects = new List();
  List<String> projectNames = ["test","test","test","test"];
  List<String> workTypes = ["test","test","test","test"];
  List<Project> works = new List();

  _WorkPageState({this.cookie});

  void openSettings(){
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) =>
        new SettingsHome()));
  }

  void openMenu(){
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) =>
        new LoginActivity(cookie: cookie,)));
  }

  @override
  void initState(){
    _initState();
    init = true;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(icon: new Icon(Icons.menu), onPressed: openMenu,),
          new IconButton(icon: new Icon(Icons.exit_to_app), onPressed: _logoutDialog,)
        ],
      ),
      body: new Container(
        child: new Center(
          child: new FractionallySizedBox(
            widthFactor: 0.7,
            child: new Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Opacity(
                  opacity: init ? 1.0 : 0.0,
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      //new Text("At work "),
                      /*new Switch(value: state, onChanged: (bool value){ _saveTime(value);}),*/
                      new RaisedButton(
                        child: Text("$buttonState"),
                        color: Colors.deepOrangeAccent,
                        splashColor: Colors.deepOrange,
                        textColor: Colors.black,
                        elevation: 0.0,
                        onPressed: (){
                          _saveTime();
                        },
                      ),
                    ],
                  ),
                ),

                new Opacity(opacity: state ? 1.0 : 0.0, child: new Column(
                  children: <Widget>[
                    new Text(timeStarted),
                    new Divider(height: 20.0, color: Colors.white,),
                    new Row(
                      children: <Widget>[
                        new Text("Project", style: new TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                          textScaleFactor: 1.1,),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new DropdownButton(
                            onChanged: (String value){
                              _onChange(value);
                            },
                            value: projectName,
                            items: projectNames.toList().map((String value){
                              return new DropdownMenuItem(
                                value: value,
                                child: new Container(
                                  child: new Text (value),
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
                        new Text("Work type", style: new TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                          textScaleFactor: 1.1,),
                      ],
                    ),
                    new Row(
                      children: <Widget>[
                        new DropdownButton(
                            onChanged: (String value){
                              _onWorkTypeChange(value);
                            },
                            value: workType,
                            items: workTypes.toList().map((String value){
                              return new DropdownMenuItem(
                                value: value,
                                child: new Container(
                                  child: new Text (value),
                                  width: 200.0,
                                ),
                                //200.0 to 100.0
                              );
                            }).toList())
                      ],
                    ),
                  ],
                ),),
              ],
            ),
          ),
        ),
        )
    );
  }



  void _onWorkTypeChange(String value){
    setState(() {
      workType = value;
    });
  }

  void _onChange(String value) async{
    int id;
    setState((){
      projectName = value;

      for(int i = 0;i < projects.length; i++){
        if(projectName == projects[i].projectName){
          id = projects[i].projectId;
        }
      }
    });

    var response2 = await http.get('https://tmtest.artin.cz/data/projects/$id/work-types', headers: {"cookie" : cookie});

    List workData = json.decode(response2.body);

    setState((){
      workTypes.clear();
      for(int j = 0; j < workData.length; j++){
        workTypes.add(workData[j]['name'].toString());
        works.add(new Project(projectName: workData[j]['name'], projectId: workData[j]['id']));
        print("DRUHY ZADANI" + workData[j]['id'].toString());
      }
      workType = workTypes.first;
    });
  }

  Future<Null> _logoutDialog() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Are you sure you want to logout?'),
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                /*new Text('You will never be satisfied.'),
                new Text('You\’re like me. I’m never satisfied.'),*/
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  _logout() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("timeFrom","");
    sharedPreferences.setString("username", "");
    sharedPreferences.setString("password", "");

    Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) =>
        new MyApp()));
  }

  _initState() async{
    projectNames.clear();
    workTypes.clear();
    var response = await http.get('https://tmtest.artin.cz/data/main/user', headers: {"cookie" : cookie});
    print("${response.statusCode}");
    print(response.body);
    userId = json.decode(response.body)['user']['id'];

    var response3 = await http.get('https://tmtest.artin.cz/data/projects/most-frequent-and-assigned-of-user', headers: {"cookie" : cookie});
    List availableProjects = json.decode(response3.body);

    for(int j = 0;j < availableProjects.length; j++){
      projects.add(new Project(projectName: availableProjects[j]['name'], projectId: availableProjects[j]['id']));
      projectNames.add(availableProjects[j]['name']);
    }

    int id = projects[0].projectId;

    var response2 = await http.get('https://tmtest.artin.cz/data/projects/$id/work-types', headers: {"cookie" : cookie});

    projectName = projectNames.first;

    List workData = json.decode(response2.body);

    for(int j = 0; j < workData.length; j++){
      workTypes.add(workData[j]['name'].toString());
      works.add(new Project(projectName: workData[j]['name'], projectId: workData[j]['id']));
      print("PRVNI ZADANI" + workData[j]['id'].toString());
    }
    workType = workTypes.first;

    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      if(sharedPreferences.getString("timeFrom") != ""){
          state = true;
          buttonState = "Stop working";
          timeStarted = "Started at "+sharedPreferences.getString("timeFrom").substring(10,16);
      }else{
        timeStarted = "";
        buttonState = "Start working";
        state = false;
      }
    });

  }

  _saveTime() async{
    String now = new DateTime.now().toString();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String dateFrom;
    setState((){
      if(counter % 2 == 0) {
        buttonState = "Stop working";
        state = true;
      }else{
        state = false;
        buttonState = "Start working";
      }
      counter++;
      if(state){
        sharedPreferences.setString("timeFrom", now);
        timeStarted = "Started at "+now.substring(10,16);
      }else{
        print(sharedPreferences.getString("timeFrom"));
        dateFrom = sharedPreferences.getString("timeFrom");
        sharedPreferences.setString("timeFrom", "");
        print(now);
      }
    });

    if(!state){
      String fDateTo;
      String fDateFrom;
      if(getMinutes(dateFrom) == 60){
        fDateFrom =
            dateFrom.substring(0, 10) + "T" + dateFrom.substring(11, 14) + "00:00+03:00";
      }else {
        fDateFrom =
            dateFrom.substring(0, 10) + "T" + dateFrom.substring(11, 14)+ "00:00+03:00";
      }
      var dateTo = new DateTime.now().toIso8601String();

      if(getMinutes(dateTo) == 60){
        fDateTo = dateTo.substring(0, 10) + "T" +
            dateTo.substring(11, 14)  +
            "00:00+03:00";
      }else {
        fDateTo = dateTo.substring(0, 10) + "T" +
            dateTo.substring(11, 14) + getMinutes(dateTo).toString() +
            ":00+02:00";
      }

      var data = {
        "id" : 474191,
        "projectId" : getProjectId(projectName),
        "userId" : userId,
        "description" : null,
        "comment" : null,
        "recordType" : "W",
        "jiraIssueKey" : null,
        "workTypeId" : getWorkId(workType),
        "dateFrom" : fDateFrom,
        "dateTo" : fDateTo,
        "hours" : 5.0,
        "subproject" : null,
        "jiraWorklogId" : null
      };

      var response = await http.post("https://tmtest.artin.cz/data/work-records",
          body: JSON.encode(data), headers: {"cookie" : cookie, "Content-type" : "application/json;charset=UTF-8"});

      print("${response.statusCode}");
      print(response.body);
    }
  }

  int getMinutes(String word){
    int min = int.parse(word.substring(15,16));
    int minutes = int.parse(word.substring(14,16));

    if(min>=5){
      minutes = minutes + (10-min);
    }else{
      minutes = minutes - min;
    }
    return minutes;
  }

  double getExactHour(String time, String time2){
    return double.parse((int.parse(time.substring(11,13)) - int.parse(time2.substring(11,13))).toString()
        + "." + (1/(60/(getMinutes(time) - getMinutes(time2)))).toString().substring(2,3));
  }

  int getProjectId(String name){
    for(int i=0;i<projects.length;i++){
      if(name == projects[i].projectName){
        return projects[i].projectId;
      }
    }
  }

  int getWorkId(String name){
    for(int i=0;i<works.length;i++){
      print(works[i].projectName);
      if(name == works[i].projectName){
        return works[i].projectId;
      }
    }
  }
}

class Project {

  String projectName;

  int projectId;

  Project({this.projectName,this.projectId});
}

/*var fhour = time.substring(11,13);
    var shour = time2.substring(11,13);
    var fmin = getMinutes(time);

    var smin = getMinutes(time2);

    var rhour = int.parse(time.substring(11,13)) - int.parse(time2.substring(11,13));
    var rmin = getMinutes(time) - getMinutes(time2);

    var dmin = 1/(60/(getMinutes(time) - getMinutes(time2)));
    var ftime = (int.parse(time.substring(11,13)) - int.parse(time2.substring(11,13))).toString()
        + "." + (1/(60/(getMinutes(time) - getMinutes(time2)))).toString().substring(2,3);*/