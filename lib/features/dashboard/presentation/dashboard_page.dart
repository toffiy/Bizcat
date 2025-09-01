import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/Services/auth_service.dart';
import '../controllers/order_controller.dart';
import '../models/dash_item.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../widgets/dashboard_design.dart'; // ⬅️ Import your design file

class DashboardPage extends StatelessWidget {
  final DashboardController controller = DashboardController();
  final AuthService authService = AuthService();
  final OrderController orderController = OrderController();

  DashboardPage({super.key});

  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  final List<DashboardItem> quickActions = [
    DashboardItem(title: 'Product Catalog', icon: Icons.inventory),
    DashboardItem(title: 'Customer List', icon: Icons.people),
    DashboardItem(title: 'QR Code Generator', icon: Icons.qr_code),
    DashboardItem(title: 'Claim History', icon: Icons.history),
    DashboardItem(title: 'Sales Reports', icon: Icons.bar_chart),
    DashboardItem(title: 'Live Control', icon: Icons.live_tv),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildDashboardAppBar(
        context: context,
        sellerId: sellerId,
        authService: authService,
        controller: controller,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _buildPendingOrdersCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildDailySalesCard()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildProductsCard()),
                const SizedBox(width: 12),
                Expanded(child: _buildAnnualSalesCard()),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Quick Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              itemBuilder: (context, index) {
                final item = quickActions[index];
                return DashboardQuickActionItem(
                  item: item,
                  onTap: () => controller.handleNavigation(context, item.title),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingOrdersCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('orders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StatCard(
            title: 'Pending Orders',
            value: '—',
            icon: Icons.hourglass_empty,
            iconColor: Colors.orange,
          );
        }
        final allOrders = snapshot.data?.docs ?? [];
        final pendingOrders = allOrders.where((doc) {
          final status = (doc['status'] ?? '').toString().trim().toLowerCase();
          return status == 'pending';
        }).toList();

        return StatCard(
          title: 'Pending Orders',
          value: '${pendingOrders.length}',
          icon: Icons.hourglass_empty,
          iconColor: Colors.orange,
        );
      },
    );
  }

  Widget _buildDailySalesCard() {
    return StreamBuilder<List<MyOrder>>(
      stream: orderController.getOrdersForSeller(sellerId),
      builder: (context, snapshot) {
        double total = 0;
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        if (snapshot.hasData) {
          for (var order in snapshot.data!) {
            final orderDate =
                DateFormat('yyyy-MM-dd').format(order.timestamp);
            if (orderDate == today) {
              total += order.totalAmount;
            }
          }
        }
        return StatCard(
          title: 'Daily Sales',
          value: '₱${total.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          iconColor: Colors.green,
        );
      },
    );
  }

  Widget _buildProductsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('products')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return StatCard(
          title: 'Products',
          value: '$count',
          icon: Icons.inventory_2,
          iconColor: Colors.blue,
        );
      },
    );
  }

  Widget _buildAnnualSalesCard() {
    return StreamBuilder<List<MyOrder>>(
      stream: orderController.getOrdersForSeller(sellerId),
      builder: (context, snapshot) {
        double total = 0;
        final currentYear = DateTime.now().year;
        if (snapshot.hasData) {
          for (var order in snapshot.data!) {
            if (order.timestamp.year == currentYear) {
              total += order.totalAmount;
            }
          }
        }
        return StatCard(
          title: 'Annual Sales',
          value: '₱${total.toStringAsFixed(2)}',
          icon: Icons.bar_chart,
          iconColor: Colors.purple,
        );
      },
    );
  }
}
