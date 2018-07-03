import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_app/LoginActivity.dart';
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
        primaryColor: Colors.orange[800],
      ),
      home: new WorkPage(title: 'Time Mission',cookie: cookie,),
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
  final key = new GlobalKey<ScaffoldState>();
  final descriptionController = new TextEditingController();

  List<Project> projects = new List();
  List<String> projectNames = ["test","test"];
  List<String> workTypes = ["test","test"];
  List<Project> works = new List();

  int counter = 0;
  bool state = false;
  bool init = false;
  String text = "You are not working at the moment!";
  String timeStarted = "";
  String buttonState = "Start working";
  String cookie;
  String projectName ;
  String workType;
  int userId;

  _WorkPageState({this.cookie});



  @override
  void initState(){
    _initState();
    init = true;
    super.initState();
  }

  _onWorkTypeChange(String value) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("workType", value);
    setState(() {
      workType = value;
    });
  }

  void openMenu(){
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (context) =>
        new LoginStateful(title: 'Work Records',cookie: cookie,)));
  }
  void _onChange(String value) async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString("projectName", value);
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
      }
      if(workTypes.contains(sharedPreferences.getString("workType"))) {
        workType = sharedPreferences.getString("workType");
      }else {
        workType = workTypes.first;
      }
      //sharedPreferences.setString("workType", workType);
    });
  }

  Future<Null> _logoutDialog() async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Are you sure you want to logout?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel',textScaleFactor: 1.1, style: new TextStyle(
                  fontWeight: FontWeight.bold
              ),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Logout',textScaleFactor: 1.1, style: new TextStyle(
                  fontWeight: FontWeight.bold),),
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
    sharedPreferences.setString("cookie", "");
    Navigator.push(
        context,
        new MaterialPageRoute(builder: (context) =>
        new MyApp()));
  }

  /*INIT STATE*/
  _initState() async {
    projectNames.clear();
    workTypes.clear();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    var response = await http.get('https://tmtest.artin.cz/data/main/user',
        headers: {"cookie": cookie});
    userId = json.decode(response.body)['user']['id'];

    var response3 = await http.get(
        'https://tmtest.artin.cz/data/projects/most-frequent-and-assigned-of-user',
        headers: {"cookie": cookie});
    List availableProjects = json.decode(response3.body);

    for (int j = 0; j < availableProjects.length; j++) {
      projects.add(new Project(projectName: availableProjects[j]['name'],
          projectId: availableProjects[j]['id']));
      projectNames.add(availableProjects[j]['name']);
    }

    int id = projects[0].projectId;

    var response2 = await http.get(
        'https://tmtest.artin.cz/data/projects/$id/work-types',
        headers: {"cookie": cookie});
    try {
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
    } catch (e) {

    }

    setState((){
      if (sharedPreferences.getString("timeFrom") != "") {
        state = true;
        counter++;
        buttonState = "Stop working";
        timeStarted = "Started at" +
            sharedPreferences.getString("timeFrom").substring(10, 16);
        text = "";
        //init = true;

      } else {
        timeStarted = "";
        buttonState = "Start working";
        state = false;
        //init = true;

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
        text = "";
        state = true;
        counter++;
      }else{
        /*state = false;
        buttonState = "Start working";
        text = "You are not working at the moment!";*/
        dateFrom = sharedPreferences.getString("timeFrom");
        String fDateTo;
        String fDateFrom;
        if(getMinutes(dateFrom) == 60){
          fDateFrom =
              dateFrom.substring(0, 10) + "T" + dateFrom.substring(11, 14) + "00:00+03:00";
        }else {
          fDateFrom =
              dateFrom.substring(0, 10) + "T" + dateFrom.substring(11, 14)+ getMinutes(dateFrom).toString()+ ":00+02:00";
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
        _addDescription(fDateTo, fDateFrom);
      }
      if(state){
        sharedPreferences.setString("timeFrom", now);
        timeStarted = "Started at "+now.substring(10,16);
      }else{
        print(sharedPreferences.getString("timeFrom"));
        dateFrom = sharedPreferences.getString("timeFrom");
        sharedPreferences.setString("timeFrom", "");
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
            dateFrom.substring(0, 10) + "T" + dateFrom.substring(11, 14)+ getMinutes(dateFrom).toString()+ ":00+02:00";
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
      _addDescription(fDateTo, fDateFrom);
      /*THEREEE*/
    }
  }

  Future<Null> _addDescription(dateTo, dateFrom) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: new Text('Add description'),
          content: new TextField(
            controller: descriptionController,
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel',textScaleFactor: 1.1, style: new TextStyle(
                  fontWeight: FontWeight.bold
              ),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text('Add',textScaleFactor: 1.1, style: new TextStyle(
                  fontWeight: FontWeight.bold),),
              onPressed: () {
                Navigator.of(context).pop();
                addWork(dateFrom, dateTo, descriptionController.text);
              },
            ),
          ],
        );
      },
    );
  }

  void addWork(fDateFrom, fDateTo, description) async{
    var data = {
      "id" : 474191,
      "projectId" : getProjectId(projectName),
      "userId" : userId,
      "description" : description,
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

    if(response.statusCode == 200){
      showToastMessage("Work record added succesfully");
    }else{
      showToastMessage(json.decode(response.body)['message']);
    }

    setState(() {
      state = false;
      buttonState = "Start working";
      text = "You are not working at the moment!";
    });
    counter++;
  }

  void showToastMessage(String message){
    key.currentState.showSnackBar(new SnackBar(
      content: new Text(message),
    ));
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

  @override
  Widget build(BuildContext context) {
    return new WillPopScope(child:
    new Scaffold(
        key: key,
        appBar: new AppBar(
          title: new Text(widget.title),
          actions: <Widget>[
            new IconButton(icon: new Icon(Icons.menu),tooltip: 'work records', onPressed: openMenu,),
            new IconButton(icon: new Icon(Icons.exit_to_app),tooltip: 'logout', onPressed: _logoutDialog,)
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
                    opacity: state ? 1.0 : 0.0,
                    child : new Text(timeStarted,textScaleFactor: 1.1, style: new TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),),),

                  new Divider(height: 15.0, color: Colors.white),
                  new Opacity(
                    opacity: init ? 1.0 : 0.0,
                    child: new Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        new RaisedButton(
                          child: new Padding(
                            child: new Text("$buttonState", style: new TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                              textScaleFactor: 1.2,),
                            padding: new EdgeInsets.all(15.0),
                          ),
                          color: Colors.orange[800],
                          splashColor: Colors.orangeAccent,
                          textColor: Colors.white,
                          elevation: 4.0,
                          onPressed: (){
                            _saveTime();
                          },
                        ),
                      ],
                    ),
                  ),
                  new Divider(height: 20.0, color: Colors.white,),
                  new Opacity(opacity: state ? 0.0 : 1.0, child:  new Text(
                    text,style: new TextStyle(color: Colors.black.withOpacity(0.3)),),),
                  new Opacity(opacity: state ? 1.0 : 0.0, child: new Column(
                    children: <Widget>[
                      new Row(
                        children: <Widget>[
                          new Text("Project", style: new TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.1,),
                        ],
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.1,),
                        ],
                      ),
                      new Row(
                        mainAxisAlignment: MainAxisAlignment.center,
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
    ), );
  }
}

class Project {

  String projectName;

  int projectId;

  Project({this.projectName,this.projectId});
}