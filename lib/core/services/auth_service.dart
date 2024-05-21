import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(credential);

        // Ensure collection path is not empty
        if (userCredential.user != null) {
          String uid = userCredential.user!.uid;
          String? email = userCredential.user!.email;
          String? name = userCredential.user!.displayName;

          if (uid.isEmpty) throw AssertionError("User UID is empty");
          if (email == null || email.isEmpty) throw AssertionError("User email is empty");
          if (name == null || name.isEmpty) throw AssertionError("User name is empty");

          DocumentReference userDoc = _firestore.collection('users').doc(uid);
          
          // Set user data in Firestore
          await userDoc.set({
            'email': email,
            'name': name,
          }, SetOptions(merge: true));

          print("User signed in with Google: $uid, $email, $name");
        } else {
          throw AssertionError("UserCredential user is null");
        }
      } else {
        throw AssertionError("GoogleSignInAccount is null");
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
