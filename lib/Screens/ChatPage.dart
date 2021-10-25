import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/MenuScreen.dart';
import 'package:connect_friends/Screens/SearchChatPage.dart';
import 'package:connect_friends/Screens/addGroup.dart';
import 'package:connect_friends/Screens/chatRoom.dart';
import 'package:connect_friends/Screens/groupChatRoom.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
    setStatus('Online');
    tellUser();
  }

  Future<bool> tellUser()async{
    List req =[];
    await firestore.collection('users').doc(auth.currentUser!.uid).get().then((value){
      req = value.data()!['requests'];
      if(req.length!=0){
        notifyUser = true;
      }
    });
    return notifyUser;
  }
  void setStatus(String status) async {
    firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'status': status});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus('Online');
    } else {
      setStatus('Offline');
    }
  }

  final newStream = StreamController<List<Map<String, dynamic>>>();

  //final controller = ZoomDrawerController();
  Map<String, dynamic> currentUser = {};
  Map<String, dynamic> friend = {};
  List<dynamic> groupIds = [];
  List<bool> requestSent = [];
  bool notifyUser = false;
  List<Map<String, dynamic>> friends = [];
  List<Map<String, dynamic>> allUsers = [];
  String generateRoomId(String id1, String id2) {
    final num = id1.compareTo(id2);
    if (num > 0) {
      return '$id1-$id2';
    } else {
      return '$id2-$id1';
    }
  }

  Future<List<Map<String, dynamic>>> initialiseGroups() async {
    List<Map<String, dynamic>> groupsinfo = [];
    await firestore.collection('users').doc(auth.currentUser!.uid).get().then((value) {
      print('Expedcted groups are - ${value.data()!['groups']}');
      groupIds = value.data()!['groups'];
    });

    print('Group Ids are - $groupIds');
    groupIds.toSet().toList();
    for (int i = 0; i < groupIds.length; i++) {
     await firestore
          .collection('groups')
          .doc(groupIds[i])
          .collection('groupinfo')
          .doc(groupIds[i])
          .get()
          .then((value) {
        groupsinfo.add(value.data() ?? {});
      });
    }
    return groupsinfo;
  }
  Set myset = {};
  Future<List<Map<String, dynamic>>> initialiseFriends(List<Map<String, dynamic>> friends1) async {

    print('Function is called');
    await firestore.collection('users').doc(user!.uid).get().then((value) {
      currentUser = value.data() ?? {};
    });
    // print('Current user is - $currentUser');
    await firestore.collection('users').get().then((value) {
      for (int i = 0; i < value.docs.length; i++) {
        if (allUsers.length < value.docs.length)
          allUsers.add(value.docs[i].data());
      }
    });

    List userIds = [];
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((value) async {
      print('Expected User Ids are - ${value.data()!['friends']}');
      userIds = value.data()!['friends'];
      print('Friends userIds are - $userIds');
    });

    List temp = [];
    int flag=0;
    for(int i=0;i<userIds.length;i++){
      for(int j=i+1;j<userIds.length;j++){
        print('$i - $j');
        if(userIds[i]==userIds[j]){
          print('removing - ${userIds[i]} -because $i - $j');
          flag=1;
          break;
        }
      }
      if(flag==0){
        temp.add(userIds[i]);
      }
      flag=0;
    }

    friends = [];
    List<bool> isDone = [];
    for (int i = 0; i < temp.length; i++) {
      isDone.add(false);
    }
    for (int i = 0; i < temp.length; i++) {
      print('$i round started');
      await firestore.collection('users').doc(temp[i]).get().then((value) {
        print('$i value of UserIds - ${temp[i]}');
        if (true) {
          print(value.data()!['email']);
          print('myset - $myset');
          print(myset.any((e) => !(e['email'] == value.data()!['email'])));
          friends1.add(value.data() ?? {});
          friends.add(value.data() ?? {});
          myset.add(value.data() ??{});
          print('Friends after adding UserIds are - $friends1');
          isDone[i] = true;
        }
      });
      print('$i round completed');
    }

    friends.toSet().toList();
    friends1.toSet().toList();
    print('Friends are - $friends');
    return friends1;
  }

  @override
  Widget build(BuildContext context) {
    return mainScreen(context);
  }

  SafeArea mainScreen(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    //final controller = new DrawerController(child: MenuScreen(), alignment: DrawerAlignment.start);
    return SafeArea(
      child: Scaffold(
        onDrawerChanged: (val){
          if(val){
            setState(() {
              friends =[];
            });
          }else{
          }
        },
          drawer: MenuScreen(),
          backgroundColor: primary2,
          body: Builder(
            builder: (context) {
                return Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: appBar(context),
                          ),
                          //Text('New Group'),
                          Padding(
                            padding: const EdgeInsets.only(left: 20, top: 20),
                            child: FutureBuilder(
                              future: initialiseGroups(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  if (snapshot.hasError) {
                                    return Text('Unable to Load groups!');
                                  } else if (snapshot.hasData) {
                                    List<Map<String, dynamic>> groups = snapshot
                                        .data as List<Map<String, dynamic>>;
                                    return Container(
                                      width: size.width,
                                      height: 90,
                                      child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: groups.length+1,
                                          itemBuilder: (context, index) {
                                            if (index == 0) {
                                              return groupAddWidget();
                                            } else {
                                              return groupWidget(
                                                  groups[index-1]['groupicon'],
                                                  groups[index-1]['groupname'],
                                                  groups[index-1]['groupid']
                                              );
                                            }
                                          }),
                                    );
                                  }
                                }
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                            color: bgColor2,
                            boxShadow: [
                              BoxShadow(
                                  offset: Offset(0, -1),
                                  blurRadius: 3,
                                  spreadRadius: 0.5,
                                  color: Colors.black)
                            ],
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(50),
                                topLeft: Radius.circular(50))),
                        child: FutureBuilder(
                          future: initialiseFriends([]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              if (snapshot.hasError) {
                                return Text('Error Occured');
                              } else if (snapshot.hasData) {
                                final myFriends =
                                    snapshot.data as List<Map<String, dynamic>>;
                                if (myFriends.length != 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        top: 20, left: 20, right: 20),
                                    child: ListView.separated(
                                        itemBuilder: (context, index) {
                                          return friendTile(myFriends, index);
                                        },
                                        separatorBuilder: (context, index) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                                left: 10, right: 10),
                                            child: Divider(
                                              height: 10,
                                              color: Colors.black26,
                                            ),
                                          );
                                        },
                                        itemCount: myFriends.length),
                                  );
                                }

                                return addFriendsButton(size, context);
                              }
                            }
                            return Center(
                              child: CircularProgressIndicator(
                                color: primary2,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                );
            },
          )),
    );
  }

  Container groupWidget(String imgUrl, String name,String groupId) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context,
              MaterialPageRoute(builder: (_)=>groupChatRoom(groupId, name))
              );
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: bgColor2,
              backgroundImage: NetworkImage(imgUrl),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Flexible(
              child: Text(
            name,
            style: GoogleFonts.lato(
                fontWeight: FontWeight.bold, color: Colors.black),
          )),
        ],
      ),
    );
  }

  Container groupAddWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => addGroup()));
            },
            child: CircleAvatar(
              radius: 30,
              backgroundColor: bgColor2,
              backgroundImage: NetworkImage(
                  'https://icon-library.com/images/add-people-icon/add-people-icon-22.jpg',
                scale: 1
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Flexible(
              child: Text(
            '+New Group',
            style: GoogleFonts.lato(
                fontWeight: FontWeight.bold, color: Colors.black),
          )),
        ],
      ),
    );
  }

  ListTile friendTile(List<Map<String, dynamic>> myFriends, int index) {
    String status = myFriends[index]['status'];
    return ListTile(
      onTap: () {
        print(myFriends[index]['userId']);
        friend = myFriends[index];
        String roomId = generateRoomId(currentUser['userId'], friend['userId']);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => chatRoom(
                      currentUser: currentUser,
                      friend: friend,
                      roomId: roomId,
                    )));
      },
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
        status,
        style: GoogleFonts.lato(
            color: (status == 'Online') ? Colors.green : Colors.grey),
      ),
    );
  }

  Center addFriendsButton(Size size, BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'No Friends yet!',
          style: GoogleFonts.alata(fontSize: 18, fontWeight: FontWeight.w300),
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          width: size.width * 0.5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(29),
            child: FlatButton(
              padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              onPressed: () {
                for (int i = 0; i < allUsers.length; i++) {
                  requestSent.add(false);
                }
                print('while sending - $requestSent');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchChatPage(
                            true, allUsers, friends, requestSent)));
                //requestSent = [];
              },
              child: Text(
                'Add Friends',
                style: GoogleFonts.alice(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
              color: Color(0xFF6F35A5),
            ),
          ),
        ),
      ],
    ));
  }

  Row appBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: tellUser(),
              builder: (context, snapshot) {
                if(snapshot.connectionState==ConnectionState.done){
                  bool greendot = snapshot.data as bool;
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          print('Opening Menu');
                          Scaffold.of(context).openDrawer();
                        },
                        icon: Icon(Icons.menu_rounded),
                        iconSize: 28,
                        color: secondary,
                      ),
                      (greendot)?Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ):Container(),
                    ],
                  );
                }
                return CircularProgressIndicator();
              }
            ),

          ],
        ),
        Text(
          'ConnecT',
          style: GoogleFonts.alata(
              fontSize: 18, fontWeight: FontWeight.w900, color: secondary),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                for (int i = 0; i < friends.length; i++) {
                  requestSent.add(false);
                }
                print('while sending - $requestSent');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchChatPage(
                            false, allUsers, friends, requestSent)));
                //requestSent = [];
              },
              icon: Icon(Icons.search_rounded),
              iconSize: 28,
              color: secondary,
            ),
            IconButton(
              onPressed: () {
                for (int i = 0; i < allUsers.length; i++) {
                  requestSent.add(false);
                }
                print('while sending - $requestSent');
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchChatPage(
                            true, allUsers, friends, requestSent)));
                //requestSent = [];
              },
              icon: Icon(Icons.person_add_alt_1),
              iconSize: 28,
              color: secondary,
            )
          ],
        ),
      ],
    );
  }
}
