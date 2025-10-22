import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  /// [desiredRole] = "buyer" or "seller"
  Future<String?> signInWithGoogle({String desiredRole = 'seller'}) async {
    try {
      // Always sign out first to force account picker
      await _googleSignIn.signOut();
      await _auth.signOut();

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return "CANCELLED"; // user closed picker
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return "FAILED";

      final uid = user.uid;
      final email = user.email;

      // 🔎 Check if this email already exists in buyers or sellers
      final buyerQuery = await _firestore
          .collection('buyers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final sellerQuery = await _firestore
          .collection('sellers')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      // 🚫 Prevent cross-role reuse
      if (buyerQuery.docs.isNotEmpty && desiredRole != 'buyer') {
        return "ACCOUNT_EXISTS"; // already a buyer, can't be seller
      }
      if (sellerQuery.docs.isNotEmpty && desiredRole != 'seller') {
        return "ACCOUNT_EXISTS"; // already a seller, can't be buyer
      }

      // 🔹 If no conflict, proceed
      if (desiredRole == 'seller') {
        final sellerDoc = _firestore.collection('sellers').doc(uid);
        if (!(await sellerDoc.get()).exists) {
          await sellerDoc.set({
            'sellerId': uid,
            'email': email,
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
          return "NEW_ACCOUNT";
        } else {
          return "LOGIN_SUCCESS";
        }
      } else if (desiredRole == 'buyer') {
        final buyerDoc = _firestore.collection('buyers').doc(uid);
        if (!(await buyerDoc.get()).exists) {
          await buyerDoc.set({
            'buyerId': uid,
            'email': email,
            'firstName': user.displayName?.split(' ').first ?? '',
            'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });
          return "NEW_ACCOUNT";
        } else {
          return "LOGIN_SUCCESS";
        }
      }

      return "FAILED";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return "ACCOUNT_EXISTS";
      }
      return "ERROR: ${e.message}";
    } catch (e) {
      return "ERROR: $e";
    }
  }
}
