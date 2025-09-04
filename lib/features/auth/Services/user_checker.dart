import 'package:cloud_firestore/cloud_firestore.dart';

/// A helper service for checking if a user account already exists
/// in Firestore by email or phone number.
///
/// Usage:
/// ```dart
/// final checker = UserChecker();
/// bool emailTaken = await checker.emailExists("test@example.com");
/// bool phoneTaken = await checker.phoneExists("+639123456789");
/// ```
class UserChecker {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks if a user document exists with the given email.
  /// Returns `true` if found, `false` otherwise.
  Future<bool> emailExists(String email) async {
    if (email.trim().isEmpty) return false;

    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Checks if a user document exists with the given phone number.
  /// Returns `true` if found, `false` otherwise.
  ///
  /// Make sure you store phone numbers in Firestore in a consistent format
  /// (e.g., always E.164 like +63XXXXXXXXXX) so this check works reliably.
  Future<bool> phoneExists(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return false;

    final query = await _firestore
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber.trim())
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Optional: Combined check for either email or phone.
  /// Returns `true` if either exists.
  Future<bool> accountExists({
    required String email,
    required String phoneNumber,
  }) async {
    final emailTaken = await emailExists(email);
    if (emailTaken) return true;

    final phoneTaken = await phoneExists(phoneNumber);
    return phoneTaken;
  }
}
