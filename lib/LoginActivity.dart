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
    int friday = 5 - day.weekday;
    String month;

    if(day.month<10){
      month = "0"+day.month.toString();
    }else{
      month = day.month.toString();
    }

    print("day:" + day.weekday.toString());

    String thisMonday = day.year.toString()+"-"+month+"-"+((day.day - day.weekday) + 1).toString();
    String thisFriday = day.year.toString()+"-"+month+"-"+(day.day + friday).toString();
    List<String> makeDate = new List();
    makeDate.add(day.year.toString());

    var requestResponse =  await http.get('https://tmtest.artin.cz/data/work-records?filter={"dateFrom":"$thisMonday","dateTo":"2018-06-1","userId":205}'
        ,headers: {"cookie" : cookie});

    print(requestResponse.body);

    List data  = json.decode(requestResponse.body);
    if (data != null){
      for (int i = data.length-1; i >= 0; i--) {
        /*GET A WORK NAME FROM WORK ID AND BRANCH ID*/
        var id = data[i]['projectId'];
        var workId = data[i]['workTypeId'];
        var work;
        var response2 = await http.get('https://tmtest.artin.cz/data/projects/$id/work-types', headers: {"cookie" : cookie});
        print("${response2.body}");
        List workData = json.decode(response2.body);

        for(int j = 0; j < workData.length; j++){
          if(workData[j]['id'] == workId){
            work = workData[j]['name'];
          }
        }
        /*----------------------*/
        print("STILL WORKING $i");
        setState(() {
          /*EXPORT ALL VISIBLE PROJECTS*/
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
              return new Card(
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
              );
            }
          },
      ),),
      );
  }
  Future<bool> _requestPop() {
    //SystemNavigator.pop();
    print("ahoj");
    // TODO
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
    print("TIME: " + time);
    String hour = time.substring(11,16) + " - " + timeTo.substring(11,16);
    return hour;
  }

  String setTime(){
    print("TIME: " + time);
    return "Started at " + time.substring(11,16);
  }

  String calculateHour(){
    print("--------------");
    var fhour = getTime().substring(0,2);
    var fmin = getTime().substring(3,5);
    var shour = getTime().substring(8,10);
    var smin = getTime().substring(11,13);

    print(getTime().substring(0,2));
    print(getTime().substring(3,5));
    print(getTime().substring(8,10));
    print(getTime().substring(11,13));
    print("--------------");

    var rhour = int.parse(fhour) - int.parse(shour);
    var rmin = int.parse(fmin) - int.parse(smin);

    var dmin = 1/(60/rmin);
    print(rhour.toString() + "." + dmin.toString().substring(2,3));
  }

  String getExactHour(){
    print("DAATE: " + date);
    var a = date.substring(0,1);
    var b = date.substring(2,3);
   // var b = 60/(date.substring(0,3) as int);
    if(int.parse(b) != 0){
      b = (60 ~/(int.parse(b))).toString().substring(0,2) + "m";
    }else{
      b = "";
    }
    if(int.parse(a) != 0){
      a = a + "h";
    }else{
      a = "";
    }
    print(a +" "+ b);
    //print(b);
    return a +" "+ b;
  }
}

