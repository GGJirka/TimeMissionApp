import 'package:flutter/material.dart';
import 'package:flutter_app/LoginActivity.dart';
import 'package:flutter_app/WorkActivity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(
    new MyApp()
);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context){
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new MyHomePage(title: 'Time Mission'),
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
  bool _remember = true;

  @override
  void dispose(){
    loginController.dispose();
    super.dispose();
  }

  @override
  void initState(){
    getPreferences();
    super.initState();
  }

  getPreferences() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if(sharedPreferences.getString('username') != "") {
      setState(() {
        loginUser = sharedPreferences.getString('username');
        loginPass = sharedPreferences.getString('password');
        loginController.text = loginUser;
        passwordController.text = loginPass;
        _remember = true;
      });
    }
    if(loginUser != "" && loginUser != null && loginPass != "" && loginPass != null) {
      fetchPost(loginUser, loginPass);
    }
  }

  /*POST METHOD*/
  fetchPost(String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    showDialog(
      context: context,
      barrierDismissible: false,
      child: new Dialog(
        child: new Padding(
          padding: new EdgeInsets.only(
              top: 20.0, bottom: 20.0, right: 0.0, left: 0.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new CircularProgressIndicator(),
              new Divider(height: 20.0, color: Colors.white,),
              new Text("Logging in", style: new TextStyle(
              ),),
            ],
          ),
        ),
      ),
    );

    var sharedCookie = sharedPreferences.getString("cookie");

    var response = await http.get('https://tmtest.artin.cz/data/main/user', headers: {"cookie" : sharedCookie});

    if(response.statusCode == 401){
      sharedPreferences.setString("cookie", "");
    }

    if (sharedCookie == "" ||  sharedCookie== null) {
      var response = await http.post("https://tmtest.artin.cz/login",
          body: {
            "username": username,
            "password": password,
            "remember-me": "on"
          }, headers: {"content-type": "application/x-www-form-urlencoded"});

      if (response.statusCode != 500) {
        var cookie = response.headers['set-cookie'];
        sharedPreferences.setString("cookie", cookie);
        Navigator.pop(context);

        if (cookie.length > 150) {
          if (_remember) {
            SharedPreferences sharedPreferences = await SharedPreferences
                .getInstance();
            sharedPreferences.setString('username', username);
            sharedPreferences.setString('password', password);
          }
          Navigator.pushReplacement(
              context, new MaterialPageRoute(builder: (context) =>
          new WorkActivity(cookie: cookie,)));
        } else {
          return showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return new AlertDialog(
                content: new Text(
                    "Error with login. Enter a valid username and password"),
              );
            },
          );
        }
      } else {
        Navigator.pop(context);
        return showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return new AlertDialog(
              content: new Text("Couldn't connect to server"),
            );
          },
        );
      }
    }else{
      Navigator.pop(context);
      print("logged via cookie" + sharedCookie);
      Navigator.pushReplacement(
          context, new MaterialPageRoute(builder: (context) =>
      new WorkActivity(cookie: sharedPreferences.getString("cookie"),)));
    }
  }

  _rememberChange(bool value){
    setState(() {
      _remember = value;
    });
  }

  @override
  Widget build(BuildContext context){
    return new WillPopScope(child:
     new Scaffold(
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
                                labelText: 'Username',
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
                            child:  new TextField(
                              obscureText: true,
                              decoration: new InputDecoration(
                                labelText: 'Password',
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
                                  new Checkbox(value: _remember, onChanged: (bool value){_rememberChange(value);}),
                                  new Text("  Remember me"),
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
                          child: const Text('Login'),
                          color: Colors.orange[700],
                          splashColor: Colors.orangeAccent,
                          textColor: Colors.white,
                          elevation: 0.0,
                          onPressed: (){
                            fetchPost(loginController.text, passwordController.text);
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
        ),
    ),
    );
  }
}