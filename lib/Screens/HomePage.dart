import 'package:connect_friends/Screens/ChatPage.dart';
import 'package:connect_friends/Screens/LoginPage.dart';
import 'package:connect_friends/Screens/SignUpPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    final Size size =  MediaQuery.of(context).size;
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Something went Wrong!!'),
              );
            } else if (snapshot.hasData) {
              return ChatPage();
            } else {
              return firstPage(size, context);
            }
          }),
    );
  }

  Container firstPage(Size size, BuildContext context) {
    return Container(
      width: double.infinity,
      height: size.height,

      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
              left: 0,
              top: 0,
              child: Image.asset('assets/main_top.png',
                width: size.width*0.35,
              )
          ),
          Positioned(
              left: 0,
              bottom: 0,
              child: Image.asset('assets/main_bottom.png',
                width: size.width*0.2,
              )
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Welcome to Connect!',
                style: GoogleFonts.alice(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 20,),
              SvgPicture.asset('assets/chat.svg',
                width: size.width*0.8,
                height: size.height*0.4,
              ),
              SizedBox(height: 30,),
              Container(
                width: size.width*0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(vertical: 15,horizontal: 40),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>SignUpPage(true)));
                    },
                    child: Text('Login',
                      style: GoogleFonts.alice(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                      ),
                    ),
                    color: Color(0xFF6F35A5),
                  ),
                ),
              ),
              SizedBox(height: 15,),
              Container(
                width: size.width*0.8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(29),
                  child: FlatButton(
                    padding: EdgeInsets.symmetric(vertical: 15,horizontal: 40),
                    onPressed: (){
                      Navigator.push(context,
                        MaterialPageRoute(builder: (context)=> SignUpPage(false))
                      );
                    },
                    child: Text('SignUp',
                      style: GoogleFonts.alice(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                      ),
                    ),
                    color: Color(0xFFF1E6FF),
                  ),
                ),
              ),
            ],
          )

        ],
      ),
    );
  }
}
