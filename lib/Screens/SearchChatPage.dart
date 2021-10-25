import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/Screens/MenuScreen.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchChatPage extends StatefulWidget {
  bool addingFriend;
  List<Map<String, dynamic>> allUsers;

  List<Map<String, dynamic>> friends;
  List<bool> requestSent;
  //const SearchChatPage({Key? key}) : super(key: key);
  SearchChatPage(this.addingFriend, this.allUsers, this.friends,this.requestSent);

  @override
  _SearchChatPageState createState() =>
      _SearchChatPageState(addingFriend, allUsers, friends,requestSent);
}

class _SearchChatPageState extends State<SearchChatPage> {
  final user = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> allUsers;
  List<Map<String, dynamic>> friends;

  bool addingFriend;
  List<bool> requestSent;
  _SearchChatPageState(this.addingFriend, this.allUsers, this.friends,this.requestSent);

  String reqFrom = '';
  String reqToFriend = '';

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    print('after recieving - $requestSent');
    List<Map<String, dynamic>> temp =[];
    int flag = 0;
    for(int i=0;i<allUsers.length;i++){
      for(int j=0;j<friends.length;j++){
        if(allUsers[i]['userId'] == friends[j]['userId']){
          flag = 1;
          break;
        }
      }
      if(flag==0){
        temp.add(allUsers[i]);
      }
      flag=0;
    }
    List<Map<String, dynamic>> myList = (addingFriend) ? temp : friends;
    final Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          drawer: MenuScreen(),
          backgroundColor: primary2,
          body: Builder(
            builder: (context) => Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: appBar(context),
                      ),
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
                    child: (myList.length != 0)
                        ? Padding(
                            padding: const EdgeInsets.only(
                                top: 20, left: 20, right: 20),
                            child: ListView.separated(
                                itemBuilder: (context, index) {
                                  return friendTile(myList, index);
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
                                itemCount: myList.length),
                          )
                        : addFriendsButton(size, context),
                  ),
                )
              ],
            ),
          )),
    );
  }

  Row appBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            print('Opening Menu');
            Scaffold.of(context).openDrawer();
          },
          icon: Icon(Icons.menu_rounded),
          iconSize: 28,
          color: secondary,
        ),
        Expanded(
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              hintText: 'Search',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.clear_rounded),
          iconSize: 28,
          color: secondary,
        )
      ],
    );
  }

  ListTile friendTile(List<Map<String, dynamic>> myList, int index) {
    return ListTile(
      onTap: () {
        reqToFriend = myList[index]['userId'];
        print('req to friend - $reqToFriend');
        reqFrom = user!.uid;
        print('req from is $reqFrom');
        print('Requests List is - ${myList[index]['requests']}');
        List<dynamic> requests = myList[index]['requests'];
        requests.add(reqFrom);
        List<dynamic> unique = requests.toSet().toList();
        print('unique is $requests');
        firestore.collection('users').doc(reqToFriend).update(
          {
            'requests' : unique
          }
        );
        setState(() {
          requestSent[index] = true;
        });
      },
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(myList[index]['photoUrl']),
      ),
      title: Text(
        myList[index]['name'],
        style: GoogleFonts.lato(
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        myList[index]['email'],
        style: GoogleFonts.lato(),
      ),
      trailing: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: !(requestSent[index])?Colors.blue:Colors.green,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            !(requestSent[index])?'Request':'Sent',
            style: GoogleFonts.lato(
              fontSize: 13
            ),
          ),
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
}
