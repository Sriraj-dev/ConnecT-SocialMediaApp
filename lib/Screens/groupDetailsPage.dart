import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class groupDetailsPage extends StatefulWidget {
  //const groupDetailsPage({Key? key}) : super(key: key);
  String groupId;

  groupDetailsPage(this.groupId);

  @override
  _groupDetailsPageState createState() => _groupDetailsPageState(groupId);
}

class _groupDetailsPageState extends State<groupDetailsPage> {
  String groupId;

  _groupDetailsPageState(this.groupId);

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Map<String,dynamic> details = {};
  List<Map<String,dynamic>> users  = [];
  Map<String,dynamic> admin = {};


  // Future<List<Map<String,dynamic>>> getUsers()async{
  //   print('getting Users');
  //   print('list is ${details['members'].length}- ${details['members']}');
  //
  //   print('returning Users - $users');
  //   return users;
  // }
  Future<Map<String, dynamic>> getDetails() async {

    await firestore
        .collection('groups')
        .doc(groupId)
        .collection('groupinfo')
        .doc(groupId)
        .get()
        .then((value) {
          details = value.data()??{};
    });
    await firestore.collection('users').doc(details['admin']).get().then((value){
      admin = value.data()??{};
    });
    for(int i=0;i<details['members'].length;i++){
      await firestore.collection('users').doc(details['members'][i]).get().then((value){
        users.add(value.data()??{});
        print('adding - ${value.data()}');
      });
    }

    return details;
  }

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
      print('Updating Image');
      String imageUrl = await uploadTask.ref.getDownloadURL();
      await firestore.collection('groups').doc(groupId).collection('groupinfo').doc(groupId).update({
        'groupicon' : imageUrl
      });
      setState(() {

      });
    }
  }


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // getUsers();
  }
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary2,
      ),
      backgroundColor: primary2,
      body: FutureBuilder(
        future: getDetails(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.done){
            if(snapshot.hasError){
              return Center(
                child: Text('Unable to fetch data!'),
              );
            }else if(snapshot.hasData){
              Map<String, dynamic> groupInfo = snapshot.data as Map<String, dynamic>;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 30,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 10,),
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(groupInfo['groupicon']),
                      ),
                      IconButton(
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
                        icon: Icon(Icons.edit),
                        splashRadius: 20,
                      ),
                      SizedBox(width: 15,),
                      Flexible(
                        child: Text(
                          'Admin - ${admin['name']}',
                          style: GoogleFonts.lato(
                            fontSize: 19,
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 10,),
                  Text(groupInfo['groupname'],
                    style: GoogleFonts.lato(
                      fontSize: 22,
                      fontWeight: FontWeight.bold
                    ),

                  ),
                  //SizedBox(height: 10,),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Container(
                        width: size.width*0.85,
                        decoration: BoxDecoration(
                          color: bgColor2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child:Padding(
                                  padding: const EdgeInsets.only(left: 10,right: 10,top: 20),
                                  child: ListView.separated(
                                      itemBuilder:(context,index){
                                        return friendTile(users, index);
                                      },
                                    separatorBuilder: (context,index){
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 10),
                                        child: Divider(
                                          height: 10,
                                          color: Colors.black26,
                                        ),
                                      );
                                    },
                                    itemCount: users.length,
                                  ),
                                )
                          ,
                        ),
                      ),
                    ),

                ],
              );
            }
          }
          return Center(child: CircularProgressIndicator(),);

        }
      ),
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
  ListTile friendTile(List<Map<String, dynamic>> myFriends, int index) {
    return ListTile(
      leading: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => showImage(
                      myFriends[index]['name'], myFriends[index]['photoUrl'])));
        },
        child: CircleAvatar(
          radius: 25,
          backgroundImage: NetworkImage(myFriends[index]['photoUrl']),
        ),
      ),
      title: Text(
        myFriends[index]['name'],
        style: GoogleFonts.lato(
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        myFriends[index]['email'],
        style: GoogleFonts.lato(
           ),
      ),
    );
  }

}
