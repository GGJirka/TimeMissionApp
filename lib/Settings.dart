import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsHome extends StatefulWidget{
  SettingsHome({Key key, this.title}) : super(key: key);

  final String title;

  @override
  SettingsHomeState createState() => new SettingsHomeState();

}

class SettingsHomeState extends State<SettingsHome>{

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
            title: new Text('Settings')
        ),
      body: new Container(
        child: new Center(
          child: new FractionallySizedBox(
            widthFactor: 0.8,
            child:  new Column(
              children: <Widget>[
                new Text('Change password'),
                new Divider(height: 5.0, color: Colors.black,),
                new TextField(
                  decoration: new InputDecoration(
                    labelText: 'Old password'
                  ),
                ),
                new TextField(
                  decoration: new InputDecoration(
                      labelText: 'New password'
                  ),
                ),
                new TextField(
                  decoration: new InputDecoration(
                      labelText: 'Confirm new password'
                  ),
                ),
                new RaisedButton(child: new Text("Logout"),onPressed: _logout)
              ],
            ),
          ),
        ),
      ),
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
}