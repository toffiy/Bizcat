import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ===== VALIDATION HELPERS =====

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(\+63|0)\d{9,10}$');
    return phoneRegex.hasMatch(phone.trim());
  }

  String? passwordStrengthMessage(String password) {
    final errors = <String>[];

    if (password.length < 8) errors.add("at least 8 characters");
    if (!RegExp(r'[A-Z]').hasMatch(password)) errors.add("an uppercase letter");
    if (!RegExp(r'[a-z]').hasMatch(password)) errors.add("a lowercase letter");
    if (!RegExp(r'\d').hasMatch(password)) errors.add("a number");
    if (!RegExp(r'[@$!%*?&]').hasMatch(password)) {
      errors.add("a special character (@\$!%*?&)");
    }

    return errors.isEmpty
        ? null
        : "Password must include ${errors.join(', ')}.";
  }

  // ===== LOGIN =====
  Future<String?> login(String email, String password) async {
    if (!isValidEmail(email)) return "Invalid email format.";
    if (password.isEmpty) return "Password cannot be empty.";

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Email not found. Please register first.";
      } else if (e.code == 'wrong-password') {
        return "Wrong password. Try again.";
      } else {
        return "Login failed: ${e.message}";
      }
    }
  }

  // ===== REGISTER SELLER =====
Future<String?> registerSeller({
  required String email,
  required String password,
  required String firstName,
  required String lastName,
}) async {
  if (!isValidEmail(email)) return "Invalid email format.";

  final passError = passwordStrengthMessage(password);
  if (passError != null) return passError;

  try {
    // 🔹 Check Firestore if email already exists
    final existing = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return "This email is already registered.";
    }

    // 🔹 Create user in Firebase Auth
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 🔹 Save to Firestore
    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'role': 'seller',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('sellers').doc(uid).set({
      'sellerId': uid,
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return null;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      return "This email is already registered.";
    } else if (e.code == 'weak-password') {
      return "Password is too weak.";
    } else {
      return "Registration failed: ${e.message}";
    }
  }
}


  // ===== RESET PASSWORD =====
  Future<String?> resetPassword(String email) async {
    if (!isValidEmail(email)) return "Invalid email format.";

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No account found with this email.";
      } else {
        return "Failed to reset password: ${e.message}";
      }
    }
  }

  // ===== GOOGLE SIGN-IN (Always show account picker) =====
  Future<String?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Google sign-in cancelled.";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return "Google sign-in failed.";

      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) {
        // New account
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': user.displayName?.split(' ').first ?? '',
          'lastName': user.displayName?.split(' ').skip(1).join(' ') ?? '',
          'role': 'seller',
          'createdAt': FieldValue.serverTimestamp(),
          'googleSignIn': true,
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
        return "EXISTING_ACCOUNT";
      }
    } catch (e) {
      return "Google sign-in error: $e";
    }
  }

  // ===== LOGOUT =====
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // ===== CURRENT USER =====
  User? get currentUser => _auth.currentUser;
}
