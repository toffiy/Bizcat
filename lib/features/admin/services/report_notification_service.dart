import 'package:cloud_firestore/cloud_firestore.dart';

class ReportNotificationService {
  static Future<void> sendReportNotification({
    required String sellerId,
    required String reportId,
    required String action, // "warning" or "suspension"
  }) async {
    final notificationsRef = FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .collection('notifications');

    String title;
    String message;

    if (action == "warning") {
      title = "Account Warning";
      message =
          "Your account has received a warning due to a policy violation. Please review the report and take corrective action.";
    } else if (action == "suspension") {
      title = "Account Suspended";
      message =
          "Your account has been suspended due to repeated or severe violations. Please contact support for further details.";
    } else {
      throw Exception("Invalid action type");
    }

    await notificationsRef.add({
      'type': action,
      'title': title,
      'message': message,
      'reportId': reportId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }
}
