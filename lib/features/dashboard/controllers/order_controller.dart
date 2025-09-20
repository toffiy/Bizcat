import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get all orders for a seller
  Stream<List<MyOrder>> getOrdersForSeller(String sellerId) {
    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MyOrder.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// 🔹 Get orders by status
  Stream<List<MyOrder>> getOrdersByStatus(String sellerId, String status) {
    if (sellerId.isEmpty) return Stream.value([]);

    final normalizedStatus = status.trim().toLowerCase();

    final query = _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .where('status', isEqualTo: normalizedStatus);

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MyOrder.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// 🔹 Group orders by status
  Stream<Map<String, List<MyOrder>>> getOrdersGroupedByStatus(String sellerId) {
    return getOrdersForSeller(sellerId).map((orders) {
      final Map<String, List<MyOrder>> grouped = {
        'pending': [],
        'paid': [],
        'shipped': [],
        'cancelled': [],
      };
      for (var o in orders) {
        final key = o.status.trim().toLowerCase();
        if (grouped.containsKey(key)) {
          grouped[key]!.add(o);
        }
      }
      return grouped;
    });
  }

  /// 🔹 Fetch single order
  Future<MyOrder?> getOrderById(String sellerId, String orderId) async {
    final doc = await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!doc.exists) return null;
    return MyOrder.fromMap(doc.id, doc.data()!);
  }

  /// 🔹 Stream single order
  Stream<MyOrder?> streamOrderById(String sellerId, String orderId) {
    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) =>
            doc.exists ? MyOrder.fromMap(doc.id, doc.data()!) : null);
  }

  /// 🔹 Update status
  Future<void> updateStatus(
      String sellerId, String orderId, String newStatus) async {
    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  /// 🔹 Delete order
  Future<void> deleteOrder(String sellerId, String orderId) async {
    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .delete();
  }
}
