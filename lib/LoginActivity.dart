import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Settings.dart';
import 'package:flutter_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginActivity extends StatelessWidget{
  String cookie;

  LoginActivity({this.cookie});

  /*Save user to preferences and does auto login next time*/
  @override
  Widget build(BuildContext context){
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new LoginStateful(title: 'Work Records', cookie: cookie,),
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

/*MAIN CLASSS*/
class _LoginState extends State<LoginStateful> {
  String user = "";
  String cookie;

  List<ListItem> projects = new List();
  List<ListItem> adProjects = new List();

  _LoginState({this.cookie});

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
    var day = DateTime.now();

    List<String> daysInWeek = new List();
    List<String> daysNamesInWeek = ["Monday", "Tuesday","Wednesday","Thursday","Friday"];

    for(int i=0;i<5;i++){
      daysInWeek.add(day.add(new Duration(days: -day.weekday+1+i)).toIso8601String().substring(0,10));
      print(day.add(new Duration(days: -day.weekday+1+i)).toIso8601String().substring(0,10));
    }

    String dateFrom = day.add(new Duration(days: -day.weekday+1)).toIso8601String().substring(0,10);
    String dateTo = day.add(new Duration(days: 5-day.weekday)).toIso8601String().substring(0,10);

    var requestResponse =  await http.get('https://tmtest.artin.cz/data/work-records?filter={"dateFrom":"$dateFrom","dateTo":"$dateTo","userId":205}'
        ,headers: {"cookie" : cookie});

    print(requestResponse.body);

    List data  = json.decode(requestResponse.body);
    if (data != null){

      for (int i = data.length-1; i >= 0; i--){
        /*GET A WORK NAME FROM WORK ID AND BRANCH ID*/
        var id = data[i]['projectId'];
        var workId = data[i]['workTypeId'];
        var work;
        var response2 = await http.get('https://tmtest.artin.cz/data/projects/$id/work-types', headers: {"cookie" : cookie});
        print("${response2.body}");
        List workData = json.decode(response2.body);
        print(workData);
        for(int j = 0; j < workData.length; j++){
          if(workData[j]['id'] == workId){
            work = workData[j]['name'];
          }
        }
        /*----------------------*/
        setState(() {
          /*EXPORT ALL VISIBLE PROJECTS*/
          for(int k=0;k<daysInWeek.length;k++){
            if(data[i]['dateFrom'].toString().substring(0,10) == daysInWeek[k]){
              adProjects.add(new ListItem(added: true,project: daysNamesInWeek[k]));
              daysInWeek.remove(daysInWeek[k]);
              daysNamesInWeek.remove(daysNamesInWeek[k]);
            }
          }
          //print(data[i]['id']);
          adProjects.add(new ListItem(date: data[i]['hours'].toString(), time: data[i]['dateFrom'].toString(),timeTo: data[i]['dateTo'].toString(), project: data[i]['projectName'], hour: data[i]['hours'].toString()
              ,workType: work.toString(), added: false));
        /*--------------------*/
        });
      }
    }
    for(int i=0;i<adProjects.length;i++){
      projects.add(adProjects[i]);
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
    return new WillPopScope(
        onWillPop: _requestPop, child:
     new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: (){Navigator.pop(context,true);})
      ),
      body: new ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index){
            final item = projects[index];
            if(!item.added){
              return new GestureDetector(
                //onLongPress: /*deleteDialog(index)*/,
                child: new Card(
                  child: new Padding(padding: new EdgeInsets.all(15.0),
                    child: new Row(
                      children: <Widget>[
                        new Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            new Text(item.project, style: new TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              textScaleFactor: 1.1,),
                            new Text(item.workType, style: new TextStyle(
                                color: Colors.black.withOpacity(0.4),
                                fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              textScaleFactor: 1.0,),
                            new Text(item.getDate(), style: new TextStyle(
                                color: Colors.black.withOpacity(0.4),
                                fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              textScaleFactor: 1.0,),
                            new Text(item.getTime(), style: new TextStyle(
                                color: Colors.black.withOpacity(0.4),
                                fontWeight: FontWeight.bold),
                              textAlign: TextAlign.left,
                              textScaleFactor: 1.0,),
                          ],
                        ),
                        new Expanded(
                            child: new Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                new Text(item.getExactHour(), style: new TextStyle(
                                  color: Colors.black.withOpacity(0.4),
                                  fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.left,
                                  textScaleFactor: 0.9,),
                              ],
                            )),
                      ],
                    ),
                  )
                )
              );
            }else{
              return new Padding(padding: new EdgeInsets.all(15.0),
                  child: new Text(item.project, style: new TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold
                  ),));
            }
          },
      ),),
      );
  }

  deleteDialog(index) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          //title: new Text('Add description'),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Delete',textScaleFactor: 1.1, style: new TextStyle(
                  fontWeight: FontWeight.bold
              ),),
              onPressed: () {
                  deleteRecord(index);
              },
            ),
          ],
        );
      },
    );
  }

  deleteRecord(index) async{

  }

  Future<bool> _requestPop() {
    return new Future.value(true);
  }

  /*ADD NEW WORK BASED ON USER DEFAULT VALUES*/
}

class ListItem{
  String date;
  String time;
  String timeTo;
  String project;
  String hour;
  String workType;
  String workTypeName;
  bool added;

  ListItem({this.date, this.time, this.timeTo, this.project, this.hour, this.workType, this.added});

  String getDate(){
    print("TIMEFIRST " + time);
    String year = time.substring(0,4);
    String month = time.substring(5,7);
    String day = time.substring(8,10);

    String fDay = day + ". " + month + ". " + year;
    return fDay;
  }

  String getTime(){
    String hour = time.substring(11,16) + " - " + timeTo.substring(11,16);
    return hour;
  }

  String setTime(){
    return "Started at " + time.substring(11,16);
  }

  String calculateHour(){
    print("--------------");
    var fhour = getTime().substring(0,2);
    var fmin = getTime().substring(3,5);
    var shour = getTime().substring(8,10);
    var smin = getTime().substring(11,13);

    var rhour = int.parse(fhour) - int.parse(shour);
    var rmin = int.parse(fmin) - int.parse(smin);

    var dmin = 1/(60/rmin);
    print(rhour.toString() + "." + dmin.toString().substring(2,3));
  }

  String getExactHour(){
    if(hour.length <= 3){
      print(hour.substring(2,3));
      return hour + "h";
    }else{
      return hour.substring(0,4) + "h";
    }
  }
}

