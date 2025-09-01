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

        final price = (data['price'] ?? 0) is num
            ? (data['price'] as num).toDouble()
            : double.tryParse(data['price'].toString()) ?? 0.0;

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
            ),
            ordersCount: 0,
            totalSpent: 0.0,
            lastOrderDate: lastUpdated,
          );
        }

        final buyerStats = buyersMap[email]!;
        buyerStats.ordersCount += 1;
        buyerStats.totalSpent += price;

        if (lastUpdated != null) {
          if (buyerStats.lastOrderDate == null ||
              lastUpdated.isAfter(buyerStats.lastOrderDate!)) {
            buyerStats.lastOrderDate = lastUpdated;
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

  CustomerWithStats({
    required this.customer,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
  });
}
