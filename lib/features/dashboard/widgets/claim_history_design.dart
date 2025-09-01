// lib/designs/claim_history_design.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class ClaimHistoryDesign {
  /// Search bar widget
  static Widget buildSearchBar({
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by product or customer...',
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        onChanged: (value) => onChanged(value.toLowerCase()),
      ),
    );
  }

  /// Bottom tab bar with status counts
  static Widget buildTabBar({
    required int selectedIndex,
    required List<Map<String, dynamic>> tabs,
    required Map<String, int> statusCounts,
    required ValueChanged<int> onTap,
  }) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onTap,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: List.generate(tabs.length, (index) {
        final tab = tabs[index];
        final count = statusCounts[tab['label']] ?? 0;
        return BottomNavigationBarItem(
          icon: Stack(
            children: [
              Icon(tab['icon']),
              if (count > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                        minWidth: 16, minHeight: 16),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: "${tab['label']} ($count)",
        );
      }),
    );
  }

  /// Order card widget
  static Widget buildOrderCard({
    required MyOrder order,
    required VoidCallback? onMarkPaid,
    required VoidCallback? onShip,
    required VoidCallback? onCancel,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  order.productImage.isNotEmpty == true
                      ? order.productImage
                      : "https://via.placeholder.com/80",
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.productName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("Quantity: ${order.quantity}",
                        style: const TextStyle(color: Colors.black54)),
                    Text(
                      "₱${order.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),

          // Customer details
          const Text("Customer Details",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _iconText(Icons.person,
              "${order.buyerFirstName ?? ''} ${order.buyerLastName ?? ''}"),
          _iconText(Icons.phone, order.buyerPhone ?? ''),
          _iconText(Icons.location_on, order.buyerAddress ?? ''),

          const SizedBox(height: 12),
          const Divider(),

          // Order & Status
          const Text("Order & Status",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _iconText(Icons.calendar_today,
              DateFormat('MM/dd/yyyy').format(order.timestamp)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(order.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              order.status.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status.toLowerCase() != 'paid')
                TextButton.icon(
                  icon: const Icon(Icons.attach_money, color: Colors.green),
                  label: const Text("Mark Paid"),
                  onPressed: onMarkPaid,
                ),
              if (order.status.toLowerCase() != 'shipped')
                TextButton.icon(
                  icon: const Icon(Icons.local_shipping, color: Colors.blue),
                  label: const Text("Ship"),
                  onPressed: onShip,
                ),
              if (order.status.toLowerCase() != 'cancelled')
                TextButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text("Cancel"),
                  onPressed: onCancel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for icon + text rows
  static Widget _iconText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  /// Status color mapping
  static Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.yellow.shade300;
      case 'paid':
        return Colors.green.shade300;
      case 'shipped':
        return Colors.blue.shade300;
      case 'cancelled':
        return Colors.red.shade300;
      default:
        return Colors.grey.shade300;
    }
  }
}
