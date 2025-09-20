import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerService {
  /// Fetches the seller profile document for the logged-in user
  static Future<Map<String, dynamic>?> getSellerProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(uid)
        .get();

    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  /// Fetches only the sellerId field
  static Future<String?> getSellerId() async {
    final profile = await getSellerProfile();
    return profile?['sellerId'];
  }
}
