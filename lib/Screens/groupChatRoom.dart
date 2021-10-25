import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/groupDetailsPage.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class groupChatRoom extends StatefulWidget {
  //const groupChatRoom({Key? key}) : super(key: key);
  String groupId, title;

  groupChatRoom(this.groupId, this.title);

  @override
  _groupChatRoomState createState() => _groupChatRoomState(groupId, title);
}

class _groupChatRoomState extends State<groupChatRoom> {
  String groupId, title;

  _groupChatRoomState(this.groupId, this.title);

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  Map<String, dynamic> currentUser = {};

  void getCurrentUser() async {
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((value) {
      currentUser = value.data() ?? {};
    });
  }

  onSendingMessage(String text) async {
    if (text.isNotEmpty) {
      Map<String, dynamic> message = {
        'sendBy': currentUser,
        'message': text,
        'time': FieldValue.serverTimestamp(),
        'type': ''
      };
      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .add(message);

      if (hello.hasClients) hello.jumpTo(hello.position.maxScrollExtent);
    }
  }

  File? imageFile;

  Future getImage(bool isCamera) async {
    ImagePicker _picker = new ImagePicker();
    if (isCamera) {
      await _picker.pickImage(source: ImageSource.camera).then((value) {
        if (value != null) {
          imageFile = File(value.path);
          Navigator.pop(context);
          uploadImage();
        }
      });
    } else {
      await _picker.pickImage(source: ImageSource.gallery).then((value) {
        if (value != null) {
          imageFile = File(value.path);
          Navigator.pop(context);
          uploadImage();
        }
      });
    }
  }

  Future uploadImage() async {
    String fileName = Uuid().v1();
    int flag = 1;

    await firestore
        .collection('groups')
        .doc(groupId)
        .collection('chats')
        .doc(fileName)
        .set({
      'sendBy': currentUser,
      'message': '',
      'time': FieldValue.serverTimestamp(),
      'type': 'img'
    });

    var ref = FirebaseStorage.instance
        .ref()
        .child('profilepic')
        .child('$fileName.jpg');

    var uploadTask = await ref.putFile(imageFile!).catchError((e) async {
      flag = 0;
      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .doc(fileName)
          .delete();
    });

    if (flag == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();
      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('chats')
          .doc(fileName)
          .update({'message': imageUrl});
      if (hello.hasClients) hello.jumpTo(hello.position.maxScrollExtent);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  ScrollController hello = new ScrollController();

  TextEditingController typed = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary2,
        title: Text(title),
        actions: [
          IconButton(onPressed: (){
            print('Im pressed');
            Navigator.push(context,
                MaterialPageRoute(builder: (_)=>groupDetailsPage(groupId))
            );
          }, icon: Icon(Icons.settings))
        ],
      ),
      backgroundColor: bgColor2,
      body: Container(
        width: size.width,
        height: size.height,
        child: StreamBuilder(
          stream: firestore
              .collection('groups')
              .doc(groupId)
              .collection('chats')
              .orderBy('time', descending: false)
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.data != null) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: size.width,
                      height: size.height / 1.25,
                      child: ListView.builder(
                        controller: hello,
                        itemBuilder: (context, index) {
                          return message(snapshot, index, size);
                        },
                        itemCount: snapshot.data!.docs.length,
                      ),
                    ),
                    textFeild(size, context)
                  ],
                ),
              );
            } else {
              return Container();
            }
          },
        ),
      ),
    );
  }

  InkWell inkWellButton(Icon icon, String title, Function onTap) {
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

  Padding textFeild(Size size, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: size.width * 0.9,
        decoration: BoxDecoration(
            color: Colors.grey, borderRadius: BorderRadius.circular(29)),
        child: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                  child: TextField(
                controller: typed,
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: 'Type a message'),
              )),
              IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                              children: [
                                inkWellButton(Icon(Icons.camera_alt_rounded),
                                    'Take a Picture', () {
                                  getImage(true);
                                }),
                                inkWellButton(
                                    Icon(Icons.photo), 'Choose a Picture', () {
                                  getImage(false);
                                })
                              ],

                          );
                        });
                  },
                  icon: Icon(Icons.image_rounded)),
              IconButton(
                  onPressed: () {
                    onSendingMessage(typed.text);
                    typed.clear();
                  },
                  icon: Icon(Icons.send_rounded))
            ],
          ),
        ),
      ),
    );
  }

  Widget message(
      AsyncSnapshot<QuerySnapshot<Object?>> snapshot, int index, Size size) {
    print('Message is - ${snapshot.data!.docs[index]['message']}');
    print('message sent by - ${snapshot.data!.docs[index]['sendBy']}');
    bool sentByMe =
    (snapshot.data!.docs[index]['sendBy']['email'] == currentUser['email']);
    print('sent By me - $sentByMe');
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
      alignment: sentByMe ? Alignment.centerRight : Alignment.centerLeft,
      width: size.width,
      child: (snapshot.data!.docs[index]['type'] == 'img')
          ? GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => showImage(
                      snapshot.data!.docs[index]['sendBy']['name'],
                      snapshot.data!.docs[index]['message'])));
        },
        child: Container(
         // height: size.height / 2.3,
          width: size.width / 2,
          alignment: (snapshot.data!.docs[index]['message'] == '')
              ? null
              : Alignment.center,
          child: (snapshot.data!.docs[index]['message'] != '')
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(snapshot.data!.docs[index]['sendBy']['name'],
                    style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.green
                    ),
                  ),
                  ClipRRect(
            borderRadius: (sentByMe)
                    ? BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20))
                    : BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
            child: Image.network(
                  snapshot.data!.docs[index]['message'],
                  fit: BoxFit.cover,
            ),
          ),
                ],
              )
              : Center(
            child: CircularProgressIndicator(),
          ),
        ),
      )
          : Container(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
        margin: EdgeInsets.all(5),
        decoration: messageDecoration(sentByMe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(snapshot.data!.docs[index]['sendBy']['name'],
              style: GoogleFonts.lato(
                fontSize: 14,
                color: Colors.green
              ),
            ),
            //Container(height: 1,color: Colors.grey,),
            Text(
              snapshot.data!.docs[index]['message'],
              style: GoogleFonts.lato(
                fontSize: 16,
                color: (sentByMe) ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration messageDecoration(bool sentByMe) {
    return BoxDecoration(
      borderRadius: (sentByMe)
          ? BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20))
          : BorderRadius.only(
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
      color: (sentByMe) ? Colors.cyan.shade200 : Colors.blue.shade800,
    );
  }
}
