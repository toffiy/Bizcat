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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => RecentOrdersTab(customer: customer),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${customer.firstName} ${customer.lastName}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Contact info
              _infoRow(Icons.email, customer.email),
              _infoRow(Icons.phone, customer.phone),
              _infoRow(Icons.home, customer.address),

              const Divider(height: 20),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _statItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
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

class RecentOrdersTab extends StatelessWidget {
  final Customer customer;
  const RecentOrdersTab({super.key, required this.customer});

  /// Safe parser for Firestore timestamp/date/string
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Recent Orders of ${customer.firstName}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: controller.getRecentOrdersForCustomer(customer.email),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No recent orders.");
              }

              final orders = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final date = _parseDate(order['lastUpdated']);
                  final productName = order['productName'] ?? 'Unknown Product';
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
        ],
      ),
    );
  }
}
