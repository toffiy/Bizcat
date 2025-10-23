import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/controllers/order_controller.dart';
import '../../dashboard/models/order.dart';
class SellerDetailPage extends StatelessWidget {
  final String sellerId;

  const SellerDetailPage({super.key, required this.sellerId});

 Future<void> _toggleSellerStatus(
    BuildContext context, String currentStatus, String sellerName) async {
  final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(newStatus == 'suspended'
          ? "Suspend Seller"
          : "Reactivate Seller"),
      content: Text(
          "Are you sure you want to set $sellerName’s status to '$newStatus'?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                newStatus == 'suspended' ? Colors.red : Colors.green,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(newStatus == 'suspended' ? "Suspend" : "Reactivate"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    // 🔹 Update seller status
    await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .update({'status': newStatus});

    // 🔹 Add log entry with seller info
    await FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .collection('logs')
        .add({
      'action': newStatus == 'suspended'
          ? 'Seller suspended'
          : 'Seller reactivated',
      'sellerId': sellerId,
      'sellerName': sellerName,
      'timestamp': FieldValue.serverTimestamp(),
      'localTimestamp': DateTime.now(),
    });

    // 🔹 Create notification for seller
    final notificationsRef = FirebaseFirestore.instance
        .collection('sellers')
        .doc(sellerId)
        .collection('notifications');

    if (newStatus == 'suspended') {
      await notificationsRef.add({
        'type': 'suspend_account',
        'title': "Account Suspended",
        'message':
            "Your account has been suspended due to policy violations. You cannot access the platform until it is reactivated.",
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } else {
      await notificationsRef.add({
        'type': 'reactivate_account',
        'title': "Account Reactivated",
        'message':
            "Your account has been reactivated. You may now continue using the platform.",
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    if (!context.mounted) return; // ✅ prevent using a dead context

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Seller status updated to $newStatus")),
  );
}
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Seller Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .snapshots(),
        builder: (context, sellerSnapshot) {
          if (sellerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!sellerSnapshot.hasData || !sellerSnapshot.data!.exists) {
            return const Center(child: Text("Seller not found"));
          }

          final data = sellerSnapshot.data!.data() as Map<String, dynamic>;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final fullName =
              "$firstName $lastName".trim().isEmpty ? "Unknown" : "$firstName $lastName";
          final email = data['email'] ?? '';
          final status = data['status'] ?? 'active';

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Seller Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                status.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              backgroundColor: status == 'suspended'
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              icon: Icon(status == 'active'
                                  ? Icons.block
                                  : Icons.lock_open),
                              label: Text(status == 'active'
                                  ? "Suspend"
                                  : "Reactivate"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: status == 'active'
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  _toggleSellerStatus(context, status, fullName),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 🔹 Products Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Products",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(
                  height: 220,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sellers')
                        .doc(sellerId)
                        .collection('products')
                        .snapshots(),
                    builder: (context, productSnapshot) {
                      if (productSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!productSnapshot.hasData ||
                          productSnapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No products found"));
                      }

                      final products = productSnapshot.data!.docs;

                      return GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product =
                              products[index].data() as Map<String, dynamic>;
                          final productName =
                              product['name'] ?? 'Unnamed Product';
                          final price = product['price'] ?? 0;
                          final imageUrl = product['imageUrl'] ?? '';

                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: imageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(8)),
                                          child: Image.network(
                                            imageUrl,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[300],
                                          child: const Center(
                                            child: Icon(Icons.image_not_supported,
                                                size: 40, color: Colors.grey),
                                          ),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(productName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text("₱$price"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const Divider(),

                // 🔹 Orders Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Latest Orders (Paid & Pending)",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(
                  height: 400,
                  child: OrdersList(sellerId: sellerId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OrdersList extends StatelessWidget {
  final String sellerId;

  const OrdersList({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController();

    return StreamBuilder<List<MyOrder>>(
      stream: orderController.getOrdersForSeller(sellerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return const Center(child: Text("No orders found"));
        }

        // 🔹 Calculate total revenue
        final totalRevenue = orders.fold<double>(0, (sum, o) {
          return sum + (o.totalAmount ?? o.price ?? 0).toDouble();
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        
            ),
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final o = orders[index];
                  final buyer = o.buyerFirstName ?? 'Unknown Buyer';
                  final price = (o.totalAmount ?? o.price ?? 0).toDouble();
                  final status = o.status ?? 'pending';
                  final orderTime = o.timestamp; // already a DateTime


                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text("Buyer: $buyer"),
                      subtitle: Text(
                        "₱${price.toStringAsFixed(2)} • "
                        "${orderTime != null ? orderTime.toLocal().toString().split(' ')[0] : 'No date'}",
                      ),
                      trailing: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'paid'
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}