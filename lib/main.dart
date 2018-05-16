import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/LoginActivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(
    new MyApp()
);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: new MyHomePage(title: 'TimeMission'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);


  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final loginController = new TextEditingController();
  final passwordController = new TextEditingController();
  LoginActivity login;
  String loginUser, loginPass;

  @override
  void dispose(){
    loginController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    getPreferences();
  }

  getPreferences() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    loginUser = sharedPreferences.getString('username');
    loginPass = sharedPreferences.getString('password');

    print(loginUser + " : " + loginPass);
    fetchPost(loginUser, loginPass);
  }

  /*POST METHOD*/
  Future<bool> fetchPost(String username, String password) async {

    var response = await http.post("https://tmtest.artin.cz/login",
        body: {"username":username,"password" : password});

    print('Response status: ${response.statusCode}');
    print(response.headers);

    var cookie = response.headers['set-cookie'];


    print(cookie);

    if(cookie.startsWith("JSESSIONID")){
      login = new LoginActivity(username, password,cookie);
      login.saveLogin();
      Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) =>
         login));
    }else{
      return showDialog(
      context: context,
      builder: (context){
        return new AlertDialog(
          content: new Text("Error with login. Enter a valid username and password"),
        );
      },
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      //UI for login
      body: new Container(
        child: new Center(
          child: new FractionallySizedBox(
            widthFactor: 0.7, // 265 / 375
            child: new Container(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Theme(
                    data: new ThemeData(
                        primaryColor: Colors.orangeAccent,
                        hintColor: Colors.black,
                        textSelectionColor: Colors.orangeAccent,
                    ),
                    child: new TextField(
                      decoration: new InputDecoration(
                        labelText: 'Username',

                      ),
                      controller: loginController,
                    ),
                  ),

                new Theme(
                  data: new ThemeData(
                      primaryColor: Colors.orangeAccent,
                      hintColor: Colors.black,
                      textSelectionColor: Colors.orangeAccent,
                  ),
                  child:  new TextField(
                    obscureText: true,
                    decoration: new InputDecoration(
                        labelText: 'Password',
                    ),
                    controller: passwordController,
                  ),
                ),

                  new Divider(
                    height: 20.0,
                    color: Colors.white,
                  ),
                  new Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      new RaisedButton(
                        child: const Text('Login'),
                        color: Colors.orangeAccent,
                        splashColor: Colors.orange,
                        textColor: Colors.black,
                        elevation: 0.0,
                        onPressed: (){
                          print(fetchPost(loginController.text, passwordController.text));
                          },
                      )
                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),

    );

  }
}