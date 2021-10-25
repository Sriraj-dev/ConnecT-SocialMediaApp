import 'package:connect_friends/Screens/ChatPage.dart';
import 'package:connect_friends/Screens/HomePage.dart';
import 'package:connect_friends/Screens/SignUpPage.dart';
import 'package:connect_friends/Services/GoogleAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showPassword = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: loginPage(size)
    );
  }

  Widget loginPage(Size size) {
    bool loggingIn =false;
    TextEditingController email = new TextEditingController();
    TextEditingController password = new TextEditingController();
    return Container(
      height: size.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Image.asset(
              'assets/main_top.png',
              width: size.width * 0.35,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              'assets/login_bottom.png',
              width: size.width * 0.5,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: GoogleFonts.alice(
                  fontWeight: FontWeight.bold,
                  fontSize: 29,
                ),
              ),
              SizedBox(
                height: 20,
              ),
              SvgPicture.asset(
                'assets/login.svg',
                width: size.width * 0.5,
                height: size.height * 0.3,
              ),
              SizedBox(
                height: 25,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30),
                child: TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(29),
                    ),
                    hintText: 'Your Email',
                    filled: true,
                    fillColor: Color(0xFFF1E6FF),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Color(0xFF6F35A5),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 30, right: 30),
                child: TextField(
                  controller: password,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(29),
                      ),
                      hintText: 'Password',
                      filled: true,
                      fillColor: Color(0xFFF1E6FF),
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Color(0xFF6F35A5),
                      ),
                      suffixIcon: showPassword
                          ? IconButton(
                              icon: Icon(
                                Icons.visibility_off,
                                color: Color(0xFF6F35A5),
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.visibility,
                                color: Color(0xFF6F35A5),
                              ),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            )),
                ),
              ),
              SizedBox(
                height: 30,
              ),
              Container(
                width: size.width * 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: FlatButton(
                    padding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    onPressed: () {
                      String _email = email.text;
                      String _password = password.text;

                      loggingIn = loginClicked(_email, _password, loggingIn);
                    },
                    child: !loggingIn?Text(
                      'Login',
                      style: GoogleFonts.alata(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ):CircularProgressIndicator(),
                    color: Color(0xFF6F35A5),
                  ),
                ),
              ),
              SizedBox(
                height: 18,
              ),
              Container(
                width: size.width * 0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: FlatButton.icon(
                    padding:
                        EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                    onPressed: () {
                      final provider = Provider.of<GoogleSignInProvider>(
                          context,
                          listen: false);
                      provider.googleLogin().then((value){
                        Navigator.pop(context);
                      }).catchError((onError){
                        showSnackBar();
                      });
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.google,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Login with Google',
                      style: GoogleFonts.alata(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    color: Color(0xFF6F35A5),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => SignUpPage(false)));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: GoogleFonts.lato(
                        color: Color(0xFF6F35A5),
                      ),
                    ),
                    Text(
                      'SignUp',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F35A5),
                      ),
                    ),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  bool loginClicked(String _email, String _password, bool loggingIn) {
    FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email, password: _password).then((value) {
          setState(() {
            loggingIn = true;
          });
          Future.delayed(Duration(seconds: 1,milliseconds: 50),(){
            Navigator.pop(context);
          });
    }).catchError((e){
      showSnackBar();
    });
    return loggingIn;
  }

  void showSnackBar() {
     final snackBar = new SnackBar(
      content: Text('Invalid Credentials!'),
      backgroundColor: Colors.red,
      padding:
      EdgeInsets.symmetric(horizontal: 10),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(snackBar);
  }
}
