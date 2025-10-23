import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/customer.dart';

class CustomerController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of customers with aggregated order stats
  Stream<List<CustomerWithStats>> getCustomersWithOrders() {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
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

  /// Stream of last 5 orders for a given customer
  Stream<List<Map<String, dynamic>>> getRecentOrdersForCustomer(
      String customerEmail) {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .where('buyerEmail', isEqualTo: customerEmail)
        .limit(5)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((d) => d.data()).toList());
  }

  /// Report a buyer with reason, description, and evidence (images).
  Future<void> reportBuyer({
    required String buyerId,
    required String buyerEmail,
    required String buyerName,
    required String reason,
    required String description,
    required List<File> evidenceFiles, // local image files
  }) async {
    final seller = FirebaseAuth.instance.currentUser;
    if (seller == null) throw Exception("Not logged in");

    final sellerId = seller.uid;

    // 🔹 Upload evidence to Cloudinary
    final List<String> evidenceUrls = [];
    for (final file in evidenceFiles) {
      final url = await _uploadToCloudinary(file);
      if (url != null) evidenceUrls.add(url);
    }

    // 🔹 Fetch seller profile info
    final sellerSnap =
        await _firestore.collection("sellers").doc(sellerId).get();
    final sellerData = sellerSnap.data() ?? {};

    final sellerInfo = {
      "sellerEmail": sellerData["email"] ?? seller.email,
      "sellerFirstName": sellerData["firstName"] ?? "",
      "sellerLastName": sellerData["lastName"] ?? "",
    };

    // 🔹 Save report in Firestore
    await _firestore
        .collection("sellers")
        .doc(sellerId)
        .collection("reports")
        .add({
      "sellerId": sellerId,
      ...sellerInfo,
      "buyerId": buyerId,
      "buyerEmail": buyerEmail,
      "buyerName": buyerName,
      "reason": reason,
      "description": description,
      "evidence": evidenceUrls,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// Helper: Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(File file) async {
    const cloudName = "ddpj3pix5";
    const uploadPreset = "bizcat_unsigned";

    final uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath("file", file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      return data["secure_url"];
    } else {
      print("Cloudinary upload failed: ${response.statusCode}");
      return null;
    }
  }
}

class CustomerWithStats {
  final Customer customer;
  int ordersCount;
  double totalSpent;
  DateTime? lastOrderDate;
  double lastPurchaseAmount;

  CustomerWithStats({
    required this.customer,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
    required this.lastPurchaseAmount,
  });
}
