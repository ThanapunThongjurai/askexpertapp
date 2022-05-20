import 'dart:convert';
import 'package:askexpertapp/config/ConfigApp.dart';
import 'package:askexpertapp/page/register_login/Register.dart';
import 'package:askexpertapp/page/register_login/RegisterInfo.dart';
import 'package:askexpertapp/page/topic/TopicPage.dart';
import 'package:askexpertapp/utils/Routes.dart';
import 'package:askexpertapp/utils/storageToken.dart';
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import "dart:io";
import 'package:get/get.dart';

import '../NavigationBar.dart';

final GoogleSignIn _googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
  ],
);

class LoginPage extends StatefulWidget {
  final plugin = FacebookLogin(debug: true);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _passWord = TextEditingController();

  //Fb login
  String? _sdkVersion;
  FacebookAccessToken? _token;
  FacebookUserProfile? _profile;
  String? _emailFb;
  String? _imageUrl;
  String? _passWordFb;

  //G login
  GoogleSignInAccount? _currentUser;
  String? _Gmail;
  String? _passWordG; //ID

  @override
  void initState() {
    //routes("token");

    _googleSignIn.signInSilently();
    _getSdkVersion();

    super.initState();
  }

  Future<void> _HandleLogin(var response) async {
    //full json DATA model form LoginCallAPi() funcion

    Map resMap = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      print('\nResponse status: ${response.statusCode}');
      print('\nResponse message: ${resMap["message"]}');
      print('\nResponse body data: ${resMap["data"]}');

      //SAVE TOKEN
      await TokenStore.setToken('${resMap["data"]}');
      String? getToken = await TokenStore.getToken();
      print("data SecureStorage : ${getToken}");
      if (resMap["message"] == "register") {
        Get.offAll(RegisterInfoPage());
      } else {
        Get.offAll(NavigationBarPage());
      }
    } else {
      print('\nResponse message: ${resMap["message"]}');
      Get.snackbar(
        "Login Report Status",
        '${resMap["message"]}',
        icon: Icon(Icons.person, color: Colors.white),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Color(ConfigApp.warningSnackBar),
        colorText: Color(ConfigApp.warningSnackBarText),
      );
    }
  }

  Future<void> _LoginCallApi() async {
    Map<String, String> params = Map();
    //Map<String, String> data = Map();
    var body = jsonEncode({'email': _email.text, 'passWord': _passWord.text});

    var url = Uri.parse('${ConfigApp.apiLogin}');
    var response = await http.post(url, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
    await _HandleLogin(response);
  }

  Future<void> _LoginCallApiFb() async {
    Map<String, String> params = Map();
    //Map<String, String> data = Map();
    var body = jsonEncode({'email': _emailFb, 'password': _passWordFb});

    var url = Uri.parse('${ConfigApp.apiLoginFacebook}');
    var response = await http.post(url, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
    await _HandleLogin(response);
  }

  Future<void> _LoginCallApiG() async {
    Map<String, String> params = Map();
    //Map<String, String> data = Map();
    var body = jsonEncode({'email': _Gmail, 'passWord': _passWordG});

    var url = Uri.parse('${ConfigApp.apiLoginGoogle}');
    var response = await http.post(url, body: body, headers: {
      "Accept": "application/json",
      "content-type": "application/json"
    });
    await _HandleLogin(response);
  }

  Future<void> _GsignIn() async {
    _googleSignIn.disconnect();
    try {
      await _googleSignIn.signIn();
    } catch (e) {
      print('Error signing in $e');
    }
    // _Gmail = _googleSignIn.currentUser?.email;
    // _passWordG = _googleSignIn.currentUser?.id;
    setState(() {
      _Gmail = _googleSignIn.currentUser?.email;
      _passWordG = _googleSignIn.currentUser?.id;
    });

    print(_Gmail);
    print(_passWordG);
    _googleSignIn.disconnect();

    await _LoginCallApiG();
  }

  Future<void> _FBsignIn() async {
    await widget.plugin.logIn(permissions: [
      FacebookPermission.publicProfile,
      FacebookPermission.email,
    ]);
    await _updateLoginInfo();
    await _LoginCallApiFb();
  }

  Future<void> _onPressedExpressLogInButton(BuildContext context) async {
    final res = await widget.plugin.expressLogin();
    if (res.status == FacebookLoginStatus.success) {
      await _updateLoginInfo();
    } else {
      await showDialog<Object>(
        context: context,
        builder: (context) => const AlertDialog(
          content: Text("Can't make express log in. Try regular log in."),
        ),
      );
    }
  }

  Future<void> _onPressedLogOutButton() async {
    await widget.plugin.logOut();
    await _updateLoginInfo();
  }

  Future<void> _getSdkVersion() async {
    final sdkVersion = await widget.plugin.sdkVersion;
    setState(() {
      _sdkVersion = sdkVersion;
    });
  }

  Future<void> _updateLoginInfo() async {
    final plugin = widget.plugin;
    final token = await plugin.accessToken;
    FacebookUserProfile? profile;
    String? email;
    String? imageUrl;

    if (token != null) {
      profile = await plugin.getUserProfile();
      if (token.permissions.contains(FacebookPermission.email.name)) {
        email = await plugin.getUserEmail();
      }
      imageUrl = await plugin.getProfileImageUrl(width: 100);
    }

    String passWordFb = profile?.toMap()["userId"];

    print("token : ${token}\n");
    print("profile : ${profile}\n");
    print("passWordFb : ${passWordFb}\n");
    print("email : ${email}\n");

    setState(() {
      _token = token;
      _profile = profile;
      _emailFb = email;
      _imageUrl = imageUrl;
      _passWordFb = passWordFb;
    });
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    );

    return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Login",
            style: TextStyle(
              color: Color(ConfigApp.textColor),
              fontSize: 32,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [],
          elevation: 0,
          centerTitle: false,
          backgroundColor: const Color(ConfigApp.appbarBg),
        ),
        backgroundColor: const Color(ConfigApp.appbarBg),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // TextFormField(
                    //   decoration: new InputDecoration(label: Text("UserName")),
                    // ),


                    Expanded(child: SingleChildScrollView(
                      child: Column(children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                          child: TextFormField(
                            cursorColor: Color(ConfigApp.cursorColor),
                            decoration: const InputDecoration(
                                icon: Icon(
                                  Icons.email,
                                  color: Color(ConfigApp.iconEmail),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                    BorderRadius.all(Radius.circular(15)),
                                    borderSide: BorderSide(
                                        color: Color(ConfigApp.buttonSecondary))),
                                label: Text("Email"),
                                hintText: "example@rmuti.ac.th"),
                            keyboardType: TextInputType.emailAddress,
                            controller: _email,
                            validator: (input) {
                              if (input!.isEmpty) {
                                return "please enter Email";
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                          child: TextFormField(
                            decoration: const InputDecoration(
                              label: Text("PassWord"),
                              icon: Icon(
                                Icons.password,
                                color: Color(ConfigApp.iconEmail),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                                  borderSide: BorderSide(
                                      color: Color(ConfigApp.buttonPrimary))),
                            ),
                            obscureText: true,
                            controller: _passWord,
                            validator: (input) {
                              if (input!.isEmpty) {
                                return "please enter PassWord";
                              } else {
                                return null;
                              }
                            },
                          ),
                        ),
                        // TextFormField(
                        //   decoration: new InputDecoration(label: Text("re-PassWord")),
                        //   obscureText: true,
                        // ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                IconButton(
                                  onPressed: () {
                                    _GsignIn();
                                  },
                                  iconSize: 40,
                                  icon: const Icon(
                                    FontAwesomeIcons.google,
                                    color: Color(ConfigApp.iconEmail),
                                  ),
                                ),
                                Text(
                                  "Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                )
                              ]),
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                        //   child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: <Widget>[
                        //         IconButton(
                        //           onPressed: () {
                        //             _FBsignIn();
                        //           },
                        //           iconSize: 40,
                        //           icon: const Icon(
                        //             FontAwesomeIcons.facebook,
                        //             color: Color(ConfigApp.iconEmail),
                        //           ),
                        //         ),
                        //         Text(
                        //           "FaceBook",
                        //           style: TextStyle(
                        //             fontSize: 16,
                        //           ),
                        //         )
                        //       ]),
                        // ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                          child: TextButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(300, 50),
                              primary: Color(ConfigApp.buttonPrimary),
                              elevation: 5,
                              shape: shape,
                              //side: BorderSide(width: 1,color: Color(Config.textColor),)
                            ),
                            onPressed: () {
                              Get.offAll(RegisterPage());
                            },
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(ConfigApp.buttonSecondary),
                              ),
                            ),
                          ),
                        ),
                      ],),
                    )),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 12.0, 0, 12.0),
                      child: TextButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(300, 50),
                          primary: Color(ConfigApp.buttonSecondary),
                          elevation: 5,
                          shape: shape,
                          //side: BorderSide(width: 1,color: Color(Config.textColor),)
                        ),
                        onPressed: () {
                          bool pass = _formKey.currentState!.validate();
                          if (pass) {
                            //_formKey.currentState!.reset();
                            _LoginCallApi();
                            print("${_email.text}");
                            print("${_passWord.text}");
                          }
                        },
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(ConfigApp.buttonPrimary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
// ElevatedButton(
//   style: ElevatedButton.styleFrom(
//     primary: Colors.red, // background
//     onPrimary: Colors.white, // foreground
//   ),
//   onPressed: () { },
//   child: Text('ElevatedButton with custom foreground/background'),
// ),
// OutlinedButton(
//
//   onPressed: () { },
//   child: Text('Looks like an OutlineButton'),
// )
