import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';


class GoogleSignInProvider extends ChangeNotifier{

  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _user;
  User? user1;
  GoogleSignInAccount get user => _user!;
  String? userId;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  Future googleLogin()async{
    try{
      final googleUser = await googleSignIn.signIn();
      if(googleUser == null) return;
      _user = googleUser;

      final googleAuth = await googleUser.authentication;

      final credentials = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

     final UserCredential authresult= await FirebaseAuth.instance.signInWithCredential(credentials);
     final User? user = authresult.user;

     if(authresult.additionalUserInfo!.isNewUser){
       if(user!=null){
         List<String> friends =[];
         List<String> requests =[];
         List<String> groups =[];
         userId = auth.currentUser!.uid;
         firestore.collection('users').doc(auth.currentUser!.uid).set({
           'name': auth.currentUser!.displayName,
           'email':auth.currentUser!.email,
           'photoUrl':auth.currentUser!.photoURL,
           'userId': userId,
           'friends':<String>[],
           'requests':<String>[],
           'groups':<String>[],
           'status':'Offline',
         });
       }
     }

      notifyListeners();
    }catch(e){
      print(e.toString());
    }

  }

  Future googleLogout()async{
    try{
      print('Logging Out');
      await googleSignIn.disconnect();
      FirebaseAuth.instance.signOut();
    }catch(e){
      FirebaseAuth.instance.signOut();
    }
    firestore
        .collection('users')
        .doc(auth.currentUser!.uid)
        .update({'status': 'Offline'});
    notifyListeners();
  }


}