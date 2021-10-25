import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/RequestsPage.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/Services/GoogleAuth.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<List> getDetails() async {
    print('User id is ${user!.uid}');
    await firestore.collection('users').doc(user!.uid).get().then((value) {
      print('value in Menu Screen is ${value.data()}');
      name = value.data()!['name'];
      photoUrl = value.data()!['photoUrl'];
    });
    print('User name is $name');
    return [];
  }

  final user = FirebaseAuth.instance.currentUser;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? name;
  String? photoUrl;

  File? imageFile;
  Future getImage(bool isCamera)async{
    ImagePicker _picker = new ImagePicker();
    if(isCamera){
      await _picker.pickImage(source: ImageSource.camera).then((value){
        if(value!=null){
          imageFile = File(value.path);
          Navigator.pop(context);
          uploadImage();
        }
      });
    }else{
      await _picker.pickImage(source: ImageSource.gallery).then((value){
        if(value!=null){
          imageFile = File(value.path);
          Navigator.pop(context);
          uploadImage();
        }
      });
    }

  }

  Future uploadImage()async{
    String fileName = Uuid().v1();
    int flag =1;

    var ref = FirebaseStorage.instance.ref().child('profilepic').child('$fileName.jpg');

    var uploadTask = await ref.putFile(imageFile!).catchError((e){
      flag = 0;
    });

    if(flag==1){
      String imageUrl = await uploadTask.ref.getDownloadURL();
      firestore.collection('users').doc(user!.uid).update({
        'photoUrl' : imageUrl
      });
      setState(() {

      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Material(
          color: primary2,
          child: Padding(
            padding:
                const EdgeInsets.only(left: 30, right: 10, top: 35, bottom: 0),
            child: FutureBuilder(
              future: getDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unable to get user Image!',
                          style: GoogleFonts.alata(
                              fontSize: 18, fontWeight: FontWeight.w300),
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        Text(
                          'Unable to get user name',
                          style: GoogleFonts.alata(
                              fontSize: 18, fontWeight: FontWeight.w300),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        IconButton(
                          onPressed: () {
                            final provider = Provider.of<GoogleSignInProvider>(
                                context,
                                listen: false);
                            provider.googleLogout();
                          },
                          icon: Icon(Icons.logout_rounded),
                          iconSize: 30,
                        )
                      ],
                    );
                  } else if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (_)=>showImage(name??'',photoUrl??''))
                                );
                              },
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage: (photoUrl != null)
                                    ? NetworkImage(
                                        photoUrl ?? '',
                                      )
                                    : NetworkImage(
                                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png'),
                              ),
                            ),
                            IconButton(
                              splashRadius: 15,
                                onPressed: (){
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return SimpleDialog(
                                            children: [inkWellButton(
                                                Icon(Icons.camera_alt_rounded),'Take a Picture',
                                                    (){
                                                  getImage(true);
                                                }
                                            ),
                                              inkWellButton(
                                                  Icon(Icons.photo),'Choose a Picture',
                                                      (){
                                                    getImage(false);
                                                  }
                                              )
                                            ],
                                        );
                                      });
                                },
                                icon: Icon(Icons.edit)
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                name ?? user!.email ?? '',
                                style: GoogleFonts.alice(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                            IconButton(onPressed: (){
                              rename(context);
                            },
                                splashRadius: 30,
                                icon: Icon(Icons.edit,size: 28,color: Colors.black,)
                            )
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        menuItem(
                          Icon(Icons.group_add_rounded,color: Colors.white,size: 29,),
                          'Friend Requests',
                                ()async{
                                 bool ischanged = await Navigator.push(context,
                                    MaterialPageRoute(builder: (context) => RequestsPage())
                                  );
                                 print(ischanged);
                                  setState(() {

                                  });
                                }
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        menuItem(
                            Icon(Icons.logout_rounded,color: Colors.white,size: 29,),
                            'Logout',
                                () {
                              final provider = Provider.of<GoogleSignInProvider>(
                                  context,
                                  listen: false);
                              provider.googleLogout();
                            }
                        ),
                      ],
                    );
                  }
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 20,
                    ),
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 20,
                    ),
                    IconButton(
                      onPressed: () {
                        final provider = Provider.of<GoogleSignInProvider>(
                            context,
                            listen: false);
                        provider.googleLogout();
                      },
                      icon: Icon(Icons.logout_rounded),
                      iconSize: 30,
                    )
                  ],
                );
              },
            ),
          )),
    );
  }
  InkWell inkWellButton(Icon icon,String title,Function onTap) {
    return InkWell(
      onTap: () {
        onTap();
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            icon,
            SizedBox(
              width: 15,
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  Future<dynamic> rename(BuildContext context) {
    TextEditingController namecontroller = new TextEditingController();
    namecontroller.text = name??'';
    return showDialog(context: context, builder: (context){
                              return AlertDialog(
                                title: Text('Edit your name!'),
                                content:
                                  TextField(
                                    controller: namecontroller,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Name cannot be Empty',
                                    ),
                                  ),

                                actions: [
                                  ElevatedButton(
                                      onPressed: (){
                                        Navigator.pop(context);
                                      },
                                      child: Text('Cancel')),
                                  ElevatedButton(
                                      onPressed: (){
                                        if(namecontroller.text.isNotEmpty){
                                          firestore.collection('users').doc(user!.uid).update({
                                            'name' : namecontroller.text
                                          });
                                          Navigator.pop(context);
                                          setState(() {

                                          });
                                        }

                                      },
                                      child: Text('Rename')),
                                ],

                              );
                            });
  }

  Widget menuItem(Icon icon,String title,Function onTap) {
    return ListTile(
      leading: icon,
      title: Text(title,
        style: GoogleFonts.balooTammudu(
          color: Colors.white,
          fontSize: 18
        ),
      ),
      onTap: (){
        onTap();
      },
    );

  }
}
