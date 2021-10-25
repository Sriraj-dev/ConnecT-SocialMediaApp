import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/showImage.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class addGroup extends StatefulWidget {
  //const addGroup({Key? key}) : super(key: key);




  @override
  _addGroupState createState() => _addGroupState();
}

class _addGroupState extends State<addGroup> {

  TextEditingController groupName = new TextEditingController();
  List<bool> isSelected = [];
  List<dynamic> selectedMembers = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool isCreating = false;
  String groupId = Uuid().v1();
  createGroup() async {
    print('trying to create group');
    print(groupName.text);
    if(groupName.text.isNotEmpty && selectedMembers.length>=1){
      print('Creating group');
      setState(() {
        isCreating = true;
      });
      String groupIcon =
          'https://cdn2.vectorstock.com/i/1000x1000/35/71/flat-group-of-people-icon-symbol-background-vector-11573571.jpg';
      await firestore
          .collection('groups')
          .doc(groupId)
          .collection('groupinfo').doc(groupId)
          .set({
      'groupid': groupId,
      'admin': auth.currentUser!.uid,
      'groupicon': groupIcon,
      'groupname':groupName.text,
      'members' : selectedMembers,
      });

      List<dynamic> adminGroups=[];
      await firestore.collection('users').doc(auth.currentUser!.uid).get().then((value){
        adminGroups = value.data()!['groups'];
      });
      adminGroups.add(groupId);
      adminGroups.toSet().toList();

      await firestore.collection('users').doc(auth.currentUser!.uid).update({
        'groups':adminGroups
      });

      for(int i=0;i<selectedMembers.length;i++){
        List<dynamic> groups =[];
        await firestore.collection('users').doc(selectedMembers[i]).get().then((value){
          groups = value.data()!['groups'];
        });
        groups.add(groupId);
        groups.toSet().toList();
        await firestore.collection('users').doc(selectedMembers[i]).update({
          'groups':groups
        });
      }

      Navigator.pop(context);
    }
  }

  Future<List<Map<String,dynamic>>> getFriends()async{
    List<Map<String,dynamic>> friends = [];
    List userIds = [];
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((value) async {
      userIds = value.data()!['friends'];
    });
    friends = [];
    List<bool> isDone = [];
    for (int i = 0; i < userIds.length; i++) {
      isDone.add(false);
      isSelected.add(false);
    }
    for (int i = 0; i < userIds.length; i++) {
      await firestore.collection('users').doc(userIds[i]).get().then((value) {
        if (isDone[i] == false) {
          friends.add(value.data() ?? {});
          isDone[i] = true;
        }
      });
    }
    friends.toSet().toList();
    print('Friends are - $friends');
    return friends;
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        elevation: 0,
        title: Text('New Group'),
        backgroundColor: primary2,
      ),
      backgroundColor: primary2,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
                  child: TextField(
                    controller: groupName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type group name',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: createButton(size),
                ),
                Text(
                  'Add your friends!',
                  style: GoogleFonts.alata(fontSize: 20),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: FutureBuilder(
              future: getFriends(),
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.done){
                  if(snapshot.hasError){
                    return Text('Error Occured!!');
                  }else if(snapshot.hasData){
                    List<Map<String,dynamic>> myFriends = snapshot.data as List<Map<String,dynamic>>;
                    return Container(
                      width: size.width,
                      decoration: BoxDecoration(
                          color: bgColor2,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(40),
                            topLeft: Radius.circular(40),
                          )),
                      child: (myFriends.length != 0)
                          ? Padding(
                        padding:
                        const EdgeInsets.only(top: 20, left: 20, right: 20),
                        child: ListView.separated(
                            itemBuilder: (context, index) {
                              return friendTile(myFriends, index);
                            },
                            separatorBuilder: (context, index) {
                              return Padding(
                                padding:
                                const EdgeInsets.only(left: 10, right: 10),
                                child: Divider(
                                  height: 10,
                                  color: Colors.black26,
                                ),
                              );
                            },
                            itemCount: myFriends.length),
                      )
                          : addFriendsButton(size, context),
                    );
                  }
                }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
              }
            ),
          )
        ],
      ),
    );
  }

  Container createButton(Size size) {
    return Container(
      width: size.width * 0.4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: FlatButton(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          onPressed: () {
              createGroup();
              print('Selected users are -$selectedMembers');
          },
          child:(isCreating)?
              Center(
                child: CircularProgressIndicator(),
              )
              :Text(
            'Create',
            style: GoogleFonts.alice(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          color: Colors.green,
        ),
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
      ],
    ));
  }

  ListTile friendTile(List<Map<String, dynamic>> myFriends, int index) {
    return ListTile(
        onTap: () {
          setState(() {
            isSelected[index] = !isSelected[index];
          });
          if (isSelected[index]) {
            selectedMembers.add(myFriends[index]['userId']);
          } else {
            selectedMembers.remove(myFriends[index]['userId']);
          }
        },
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => showImage(myFriends[index]['name'],
                        myFriends[index]['photoUrl'])));
          },
          child: CircleAvatar(
            radius: 25,
            backgroundImage: NetworkImage(myFriends[index]['photoUrl']),
          ),
        ),
        trailing: Checkbox(
          value: isSelected[index],
          onChanged: (bool? value) {
            setState(() {
              isSelected[index] = !isSelected[index];
            });
          },
        ),
        title: Text(
          myFriends[index]['name'],
          style: GoogleFonts.lato(
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          myFriends[index]['email'],
          style: GoogleFonts.lato(),
        ));
  }
}
