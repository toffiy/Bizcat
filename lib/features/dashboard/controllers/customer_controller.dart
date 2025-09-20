import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/customer.dart';

class CustomerController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<CustomerWithStats>> getCustomersWithOrders() {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
      final Map<String, CustomerWithStats> buyersMap = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final email = (data['buyerEmail'] ?? '').toString();
        if (email.isEmpty) continue;

        final firstName = (data['buyerFirstName'] ?? '').toString();
        final lastName = (data['buyerLastName'] ?? '').toString();
        final phone = (data['buyerPhone'] ?? '').toString();
        final address = (data['buyerAddress'] ?? '').toString();
        final photoUrl = (data['buyerPhotoURL'] ?? '').toString();

        final price = (data['price'] ?? 0) is num
            ? (data['price'] as num).toDouble()
            : double.tryParse(data['price'].toString()) ?? 0.0;

        final quantity = (data['quantity'] ?? 1) is num
            ? (data['quantity'] as num).toInt()
            : int.tryParse(data['quantity'].toString()) ?? 1;

        final lastUpdated = data['lastUpdated'] is Timestamp
            ? (data['lastUpdated'] as Timestamp).toDate()
            : null;

        if (!buyersMap.containsKey(email)) {
          buyersMap[email] = CustomerWithStats(
            customer: Customer(
              id: email,
              firstName: firstName,
              lastName: lastName,
              email: email,
              address: address,
              phone: phone,
              photoUrl: photoUrl,
            ),
            ordersCount: 0,
            totalSpent: 0.0,
            lastOrderDate: lastUpdated,
            lastPurchaseAmount: 0.0,
          );
        }

        final buyerStats = buyersMap[email]!;
        buyerStats.ordersCount += 1;
        buyerStats.totalSpent += price * quantity;

        // If this order is more recent than the stored last order, update last purchase info
        if (lastUpdated != null) {
          if (buyerStats.lastOrderDate == null ||
              lastUpdated.isAfter(buyerStats.lastOrderDate!)) {
            buyerStats.lastOrderDate = lastUpdated;
            buyerStats.lastPurchaseAmount = price * quantity;
          }
        }
      }

      return buyersMap.values.toList();
    });
  }
}

class CustomerWithStats {
  final Customer customer;
  int ordersCount;
  double totalSpent;
  DateTime? lastOrderDate;
  double lastPurchaseAmount; // ✅ New field

  CustomerWithStats({
    required this.customer,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
    required this.lastPurchaseAmount,
  });
}
