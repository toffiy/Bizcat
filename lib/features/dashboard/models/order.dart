import 'package:cloud_firestore/cloud_firestore.dart';

class MyOrder {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double price;
  final double totalAmount;
  final String status;
  final DateTime timestamp;
  final String? notes;

  // 🔹 Buyer details
  final String? buyerId;
  final String? buyerFirstName;
  final String? buyerLastName;
  final String? buyerAddress;
  final String? buyerPhone;
  final String? buyerEmail;

  MyOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.status,
    required this.timestamp,
    this.notes,
    required this.buyerId,
    required this.buyerFirstName,
    required this.buyerLastName,
    required this.buyerAddress,
    required this.buyerPhone,
    required this.buyerEmail,
  });

  factory MyOrder.fromMap(String id, Map<String, dynamic> data) {
    return MyOrder(
      id: id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImage: data['productImage'] ?? '',
      quantity: (data['quantity'] ?? 0).toInt(),
      price: (data['price'] ?? 0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',

      // ✅ Safe timestamp conversion
      timestamp: data['timestamp'] != null && data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),

      notes: data['notes'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerFirstName: data['buyerFirstName'] ?? '',
      buyerLastName: data['buyerLastName'] ?? '',
      buyerAddress: data['buyerAddress'] ?? '',
      buyerPhone: data['buyerPhone'] ?? '',
      buyerEmail: data['buyerEmail'] ?? '',
    );
  }
}
