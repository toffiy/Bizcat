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

  /// 🔹 Get all orders for a buyer (across sellers)
  Stream<List<MyOrder>> getOrdersForBuyerFrom(String buyerId) {
    return FirebaseFirestore.instance
        .collectionGroup('orders')
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return MyOrder.fromMap(doc.id, data);
      }).toList();
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
  Future<List<MyOrder>> getOrdersOnce(String sellerId, String status) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders');

    if (status != 'all') {
      query = query.where('status', isEqualTo: status);
    }

    final snap = await query.orderBy('timestamp', descending: true).get();

    final orders = snap.docs.map((d) => MyOrder.fromMap(d.id, d.data())).toList();

    if (status == 'all') {
      return orders.where((o) => o.status.toLowerCase() != 'cancelled').toList();
    } else {
      return orders;
    }
  }

  /// 🔹 Batch mark multiple orders as seen
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

  /// 🔹 Update status of a single order (with stock rollback on cancel)
 /// 🔹 Update status of a single order (with quantity rollback on cancel)
Future<void> updateStatus(
  String sellerId,
  String orderId,
  String newStatus, {
  String? paymentMethod,
}) async {
  final ref = _firestore
      .collection('sellers')
      .doc(sellerId)
      .collection('orders')
      .doc(orderId);

  // Get the order data first
  final snap = await ref.get();
  final orderData = snap.data();
  if (orderData == null) return;

  final order = MyOrder.fromMap(orderId, orderData);

  // Prepare update payload
  final data = {
    'status': newStatus,
    'updatedAt': DateTime.now(),
  };

  if (paymentMethod != null) {
    data['paymentMethod'] = paymentMethod;
  }

  // Update the order status
  await ref.update(data);

  // 🔹 If cancelled → restore product quantity
  // 🔹 If cancelled → restore product quantity
if (newStatus.toLowerCase() == 'cancelled') {
  final productRef = _firestore
      .collection('sellers')
      .doc(sellerId) // ✅ use function parameter
      .collection('products')
      .doc(order.productId);

  await _firestore.runTransaction((txn) async {
    final productSnap = await txn.get(productRef);
    if (productSnap.exists) {
      final currentQty = productSnap['quantity'] ?? 0;
      txn.update(productRef, {
        'quantity': currentQty + order.quantity, // add back cancelled qty
      });
    }
  });
}
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

  /// 🔹 Mark order seen in notification feed
  Future<void> markOrderSeenInNotification(String sellerId, String orderId) async {
    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .doc(orderId)
        .update({'seenNotification': true});
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
