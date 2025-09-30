import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Get all orders for a seller (live stream, ordered by timestamp)
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

  /// 🔹 Get orders by status (live stream)
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

  /// 🔹 One-time fetch of orders for a seller by status
  /// Requires composite index: (status ASC, timestamp DESC)
  Future<List<MyOrder>> getOrdersOnce(String sellerId, String status) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders');

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    // ✅ Always order by timestamp (requires index if combined with where)
    final snap = await query.orderBy('timestamp', descending: true).get();

    final orders = snap.docs.map((d) => MyOrder.fromMap(d.id, d.data())).toList();

    if (status == 'all') {
      // ✅ Exclude cancelled in memory
      return orders.where((o) => o.status.toLowerCase() != 'cancelled').toList();
    } else {
      return orders;
    }
  }

  /// 🔹 Batch mark multiple orders as seen (prevents lag)
  Future<void> markOrdersAsSeenBatch(String sellerId, List<MyOrder> orders) async {
    final batch = _firestore.batch();
    for (var o in orders.where((o) => !o.seenBySeller)) {
      final ref = _firestore
          .collection('sellers')
          .doc(sellerId)
          .collection('orders')
          .doc(o.id);
      batch.update(ref, {'seenBySeller': true});
    }
    await batch.commit();
  }

  /// 🔹 Update status of a single order
Future<void> updateStatus(
  String sellerId,
  String orderId,
  String newStatus, {
  String? paymentMethod,
}) async {
  final data = {
    'status': newStatus,
    'updatedAt': DateTime.now(),
  };

  if (paymentMethod != null) {
    data['paymentMethod'] = paymentMethod; // ✅ Save Cash/GCash
  }

  await _firestore
      .collection('sellers')
      .doc(sellerId)
      .collection('orders')
      .doc(orderId)
      .update(data);
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

  /// 🔹 Mark single order as seen
  Future<void> markAsSeen(String sellerId, String orderId) async {
    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .update({'seenBySeller': true});
  }
}
