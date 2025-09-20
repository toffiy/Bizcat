import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';

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
    return Card(
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
                      : null, // ✅ show photo if available
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
                      Text(
                        'Customer ID: ${customer.id}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
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
