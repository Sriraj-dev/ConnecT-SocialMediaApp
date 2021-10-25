import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connect_friends/configuration.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({Key? key}) : super(key: key);

  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<dynamic> requestIds = [];
  List<Map<String, dynamic>> requests = [];

  Map<String, dynamic> currentUser = {};
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getRequests() async {
    requestIds = [];
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((value) {
      currentUser = value.data() ?? {};
      requestIds = value.data()!['requests'];
      print('requestIds are - ${value.data()!['requests']}');
    });
    print('Requests are - $requestIds');
    requests = [];
    for (int i = 0; i < requestIds.length; i++){
      await firestore
          .collection('users')
          .doc(requestIds[i])
          .get()
          .then((value) {
          requests.add(value.data() ?? {});
      });
    }
    print('requests are - $requests');
    return requests;
  }

  acceptRequest(Map<String, dynamic> reqFrom) async {
    List<dynamic> friends1 = currentUser['friends'];
    friends1.add(reqFrom['userId']);
    friends1.toSet().toList();
    List<dynamic> requests1 = currentUser['requests'];
    requests1.remove(reqFrom['userId']);
    requests1.toSet().toList();
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'friends': friends1, 'requests': requests1});

    List<dynamic> friends2 = reqFrom['friends'];
    friends2.add(currentUser['userId']);
    friends2.toSet().toList();
    await firestore
        .collection('users')
        .doc(reqFrom['userId'])
        .update({'friends': friends2});
    setState(() {

    });
  }

  rejectRequest(Map<String, dynamic> reqFrom) async {
    List<dynamic> requests2 = currentUser['requests'];
    requests2.remove(reqFrom['userId']);
    requests2.toSet().toList();
    await firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'requests': requests2});
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ()async{
        Navigator.pop(context,true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Friend Requests'),
          backgroundColor: primary2,
        ),
        body: StreamBuilder<Object>(
            stream: firestore
                .collection('users')
                .doc(auth.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if(snapshot.data!=null){
                return FutureBuilder(
                  future: getRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      List<Map<String, dynamic>> myRequests =
                      snapshot.data as List<Map<String, dynamic>>;
                      return ListView.builder(
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    radius: 25,
                                    backgroundImage:
                                    NetworkImage(myRequests[index]['photoUrl']),
                                  ),
                                  title: Text(myRequests[index]['name']),
                                  subtitle: Text(myRequests[index]['email']),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    FlatButton(
                                      onPressed: () {
                                        acceptRequest(myRequests[index]);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.blue,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text(
                                            'Accept',
                                            style: GoogleFonts.lato(
                                                color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ),
                                    FlatButton(
                                      onPressed: () {
                                        rejectRequest(myRequests[index]);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          color: Colors.red.shade400,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Text(
                                            'Reject',
                                            style: GoogleFonts.lato(
                                                color: Colors.white, fontSize: 13),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          },
                          itemCount: myRequests.length);
                    } else {
                      return Container();
                    }
                  },
                );
              }
              return Container();

            }),
      ),
    );
  }
}
