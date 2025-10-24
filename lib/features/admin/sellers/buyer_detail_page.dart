import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../dashboard/controllers/order_controller.dart';
import '../../dashboard/models/order.dart';

class BuyerDetailPage extends StatelessWidget {
  final String buyerId;

  const BuyerDetailPage({super.key, required this.buyerId});

  Future<void> _toggleBuyerStatus(
      BuildContext context, String currentStatus, String buyerName) async {
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == 'suspended'
            ? "Suspend Buyer"
            : "Reactivate Buyer"),
        content: Text(
            "Are you sure you want to set $buyerName’s status to '$newStatus'?"),
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
      // 🔹 Update buyer status
      await FirebaseFirestore.instance
          .collection('buyers')
          .doc(buyerId)
          .update({'status': newStatus});

      // 🔹 Add log entry
      await FirebaseFirestore.instance
          .collection('buyers')
          .doc(buyerId)
          .collection('logs')
          .add({
        'action': newStatus == 'suspended'
            ? 'Buyer suspended'
            : 'Buyer reactivated',
        'buyerId': buyerId,
        'buyerName': buyerName,
        'timestamp': FieldValue.serverTimestamp(),
        'localTimestamp': DateTime.now(),
      });

      // 🔹 Create notification for buyer
      final notificationsRef = FirebaseFirestore.instance
          .collection('buyers')
          .doc(buyerId)
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Buyer status updated to $newStatus")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Buyer Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('buyers')
            .doc(buyerId)
            .snapshots(),
        builder: (context, buyerSnapshot) {
          if (buyerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!buyerSnapshot.hasData || !buyerSnapshot.data!.exists) {
            return const Center(child: Text("Buyer not found"));
          }

          final data = buyerSnapshot.data!.data() as Map<String, dynamic>;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final fullName =
              "$firstName $lastName".trim().isEmpty ? "Unknown" : "$firstName $lastName";
          final email = data['email'] ?? '';
          final status = data['status'] ?? 'active';
          final phone = data['phone'] ?? '';
          final address = data['address'] ?? '';

          return SingleChildScrollView(
            child: Column(
              children: [
                // 🔹 Buyer Info Card
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
                        const SizedBox(height: 4),
                        Text("Phone: $phone"),
                        Text("Address: $address"),
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
                                  _toggleBuyerStatus(context, status, fullName),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(),

                // 🔹 Orders Section
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Past Orders",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(
                  height: 400,
                  child: BuyerOrdersList(buyerId: buyerId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


class BuyerOrdersList extends StatelessWidget {
  final String buyerId;

  const BuyerOrdersList({super.key, required this.buyerId});

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController();

    return StreamBuilder<List<MyOrder>>(
      stream: orderController.getOrdersForBuyerFrom(buyerId),
      builder: (context, snapshot) {
        // 🔹 Handle error state
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // 🔹 Show loader while waiting for first data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔹 If no data yet
        if (!snapshot.hasData) {
          return const Center(child: Text("Loading orders..."));
        }

        final orders = snapshot.data!;
        if (orders.isEmpty) {
          return const Center(child: Text("No past orders found"));
        }

        // 🔹 Render orders list
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
            final productName = o.productName ?? 'Unknown Product';
            final price = (o.totalAmount ?? o.price ?? 0).toDouble();
            final status = o.status ?? 'pending';
            final orderTime = o.timestamp;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: Text(productName),
                subtitle: Text(
                  "₱${price.toStringAsFixed(2)} • "
                  "${orderTime != null ? orderTime.toLocal().toString().split(' ')[0] : 'No date'}",
                ),
                trailing: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: status == 'paid'
                        ? Colors.green
                        : status == 'pending'
                            ? Colors.orange
                            : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}