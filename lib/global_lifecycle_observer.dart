import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GlobalLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      await _endLiveAndHideAll();
    }
  }

  Future<void> _endLiveAndHideAll() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;

      // Hide all products
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(userId)
          .collection('products')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var productDoc in productsSnapshot.docs) {
        batch.update(productDoc.reference, {'isVisible': false});
      }

      // Update seller live status
      final sellerRef = FirebaseFirestore.instance.collection('sellers').doc(userId);
      batch.update(sellerRef, {
        'isLive': false,
        'fbLiveLink': FieldValue.delete(),
      });

      await batch.commit();

      debugPrint("✅ Global cleanup: Live ended and products hidden.");
    } catch (e) {
      debugPrint("❌ Global cleanup error: $e");
    }
  }
}
