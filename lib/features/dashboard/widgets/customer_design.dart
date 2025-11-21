import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';
import '../controllers/customer_controller.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;
  final String initials;
  final int ordersCount;
  final double totalSpent;
  final DateTime? lastOrderDate;

  const CustomerInfoCard({
    super.key,
    required this.customer,
    required this.initials,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => CustomerDetailSheet(
            customer: customer,
            initials: initials,
            ordersCount: ordersCount,
            totalSpent: totalSpent,
            lastOrderDate: lastOrderDate,
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.indigo.shade100,
                backgroundImage: customer.photoUrl.isNotEmpty
                    ? NetworkImage(customer.photoUrl)
                    : null,
                child: customer.photoUrl.isEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigo,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${customer.firstName} ${customer.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------
/// FULL DETAIL SHEET
/// ----------------------
class CustomerDetailSheet extends StatelessWidget {
  final Customer customer;
  final String initials;
  final int ordersCount;
  final double totalSpent;
  final DateTime? lastOrderDate;

  const CustomerDetailSheet({
    super.key,
    required this.customer,
    required this.initials,
    required this.ordersCount,
    required this.totalSpent,
    required this.lastOrderDate,
  });

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CustomerController();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.indigo.shade100,
                    backgroundImage: customer.photoUrl.isNotEmpty
                        ? NetworkImage(customer.photoUrl)
                        : null,
                    child: customer.photoUrl.isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.indigo,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${customer.firstName} ${customer.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(customer.email,
                            style: TextStyle(color: Colors.grey.shade700)),
                        Text(customer.phone,
                            style: TextStyle(color: Colors.grey.shade700)),
                        Text(customer.address,
                            style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem('Orders', '$ordersCount'),
                  _statItem('Total Spent', '₱${totalSpent.toStringAsFixed(2)}'),
                  _statItem(
                    'Last Order',
                    lastOrderDate != null
                        ? DateFormat('M/d/yyyy').format(lastOrderDate!)
                        : '-',
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),

              // Recent Orders
              const Text("Recent Orders",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: controller.getRecentOrdersForCustomer(customer.email),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No recent orders.");
                  }

                  final orders = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final date = _parseDate(order['lastUpdated']);
                      final productName =
                          order['productName'] ?? 'Unknown Product';
                      final productImage = order['productImage'] ?? '';
                      final price = order['price'] ?? 0;
                      final qty = order['quantity'] ?? 1;

                      return ListTile(
                        leading: productImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  productImage,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.image_not_supported, size: 40),
                        title: Text(
                          productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          "₱$price x $qty\n${date != null ? DateFormat('M/d/yyyy, h:mm a').format(date) : ''}",
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // Report Buyer Button
             SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    icon: const Icon(Icons.report),
    label: const Text(
      "Report Buyer",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
    onPressed: () {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Report Buyer"),
          content: const Text(
              "Are you sure you want to report this buyer for spamming or not claiming orders?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(context);

                try {
                  // Example: call your controller here
                  await CustomerController().reportBuyer(
                    id: customer.id, // from your Customer object
                    email: customer.email,
                    name: "${customer.firstName} ${customer.lastName}",
                    reason: "Did not claim order", // could be from a dropdown
                    description:
                        "Buyer repeatedly placed orders but never claimed them.",
                    evidenceFiles: [], // pass in picked images (File objects)
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Buyer has been reported."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error reporting buyer: $e"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text("Report"),
            ),
          ],
        ),
      );
    },
  ),
),
            ],
          ),
        );
      },
    );
  }

    Widget _statItem(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
}
