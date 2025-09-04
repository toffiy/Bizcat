import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      // Always sign out first to force account picker
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Trigger Google Sign-In (will now show all accounts)
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return "Google sign-in cancelled.";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return "Google sign-in failed.";

      // Check if user exists in Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        // New account → create record and ask for password
        await docRef.set({
          'email': user.email,
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'role': 'seller',
          'createdAt': FieldValue.serverTimestamp(),
          'googleSignIn': true,
          'hasPassword': false, // track password status
        });

        await _firestore.collection('sellers').doc(user.uid).set({
          'sellerId': user.uid,
          'email': user.email,
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return "NEW_ACCOUNT";
      } else {
        // Existing account → check if password is set
        final data = doc.data() ?? {};
        final hasPassword = data['hasPassword'] == true;

        if (!hasPassword) {
          // No password yet → prompt UI to set one
          return "SET_PASSWORD";
        } else {
          // Password already set → login complete
          return "LOGIN_SUCCESS";
        }
      }
    } catch (e) {
      return "Google sign-in error: $e";
    }
  }
}
