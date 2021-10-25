import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class chatRoom extends StatefulWidget {
  //const chatRoom({Key? key}) : super(key: key);
  String roomId;
  Map<String, dynamic> currentUser;
  Map<String, dynamic> friend;

  chatRoom(
      {required this.currentUser, required this.friend, required this.roomId});

  @override
  _chatRoomState createState() => _chatRoomState(currentUser, friend, roomId);
}

class _chatRoomState extends State<chatRoom> {
  Map<String, dynamic> currentUser;
  Map<String, dynamic> friend;
  String roomId;

  _chatRoomState(this.currentUser, this.friend, this.roomId);

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController typed = new TextEditingController();

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (hello.hasClients) hello.jumpTo(hello.position.maxScrollExtent);
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
          .collection('chatrooms')
          .doc(roomId)
          .collection('chats')
          .add(message);

      if (hello.hasClients) hello.jumpTo(hello.position.maxScrollExtent);
    }
  }

  File? imageFile;

  Future getImage(bool isCamera) async {
    ImagePicker _picker = new ImagePicker();
    if(isCamera){
      await _picker.pickImage(source: ImageSource.camera).then((value) {
        if (value != null) {
          imageFile = File(value.path);
          Navigator.pop(context);
          uploadImage();
        }
      });
    }else{
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
        .collection('chatrooms')
        .doc(roomId)
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
          .collection('chatrooms')
          .doc(roomId)
          .collection('chats')
          .doc(fileName)
          .delete();
    });

    if (flag == 1) {
      String imageUrl = await uploadTask.ref.getDownloadURL();
      await firestore
          .collection('chatrooms')
          .doc(roomId)
          .collection('chats')
          .doc(fileName)
          .update({'message': imageUrl});

      if (hello.hasClients) hello.jumpTo(hello.position.maxScrollExtent);
    }
  }

  ScrollController hello = new ScrollController();

  @override
  Widget build(BuildContext context) {
    print('current User in chat page -$currentUser ');
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: primary2,
        title: Text(
          friend['name'],
          style: GoogleFonts.changa(),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert_rounded))
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(friend['photoUrl']),
                        radius: 30,
                      ),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => showImage(
                                    friend['name'], friend['photoUrl'])));
                      },
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text(
                      friend['email'],
                      style: GoogleFonts.lato(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    )
                  ],
                ),
              ),
            ),
            Container(
              width: size.width,
              height: size.height / 1.5,
              child: StreamBuilder(
                stream: firestore
                    .collection('chatrooms')
                    .doc(roomId)
                    .collection('chats')
                    .orderBy('time', descending: false)
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.data != null) {
                    return ListView.builder(
                      controller: hello,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        return message(snapshot, index, size);
                      },
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: size.width * 0.9,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(29)),
                child: Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                          child: TextField(
                        controller: typed,
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type a message'),
                      )),
                      IconButton(
                          onPressed: () {
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
            )
          ],
        ),
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
                height: size.height / 2.5,
                width: size.width / 2,
                alignment: (snapshot.data!.docs[index]['message'] == '')
                    ? null
                    : Alignment.center,
                child: (snapshot.data!.docs[index]['message'] != '')
                    ? ClipRRect(
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
              child: Text(
                snapshot.data!.docs[index]['message'],
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: (sentByMe) ? Colors.black : Colors.white,
                ),
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
