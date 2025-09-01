import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // LOGIN
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Email not found. Please register first.";
      } else if (e.code == 'wrong-password') {
        return "Wrong password. Try again.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format.";
      } else {
        return "Login failed: ${e.message}";
      }
    }
  }

  // REGISTER SELLER (new structure)
  Future<String?> registerSeller({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Create account in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Save general user profile (optional global users collection)
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'role': 'seller',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Save seller profile directly in sellers/{sellerId}
      await _firestore.collection('sellers').doc(uid).set({
        'sellerId': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email is already registered.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format.";
      } else if (e.code == 'weak-password') {
        return "Password is too weak. Use at least 6 characters.";
      } else {
        return "Registration failed: ${e.message}";
      }
    }
  }

  // ADD PRODUCT for a seller
  Future<String?> addProduct({
    required String sellerId,
    required String name,
    required double price,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final productRef = _firestore
          .collection('sellers')
          .doc(sellerId)
          .collection('products')
          .doc(); // auto-ID

      await productRef.set({
        'productId': productRef.id,
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } catch (e) {
      return "Failed to add product: $e";
    }
  }

  // RESET PASSWORD
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "No account found with this email.";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format.";
      } else {
        return "Failed to reset password: ${e.message}";
      }
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // CURRENT USER
  User? get currentUser => _auth.currentUser;
}
