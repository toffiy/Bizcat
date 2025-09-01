// lib/pages/claim_history_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../widgets/claim_history_design.dart';

class ClaimHistoryPage extends StatefulWidget {
  const ClaimHistoryPage({super.key});

  @override
  State<ClaimHistoryPage> createState() => _ClaimHistoryPageState();
}

class _ClaimHistoryPageState extends State<ClaimHistoryPage> {
  final orderController = OrderController();
  String? sellerId;
  String searchQuery = '';
  int selectedTabIndex = 0;

  final List<Map<String, dynamic>> tabs = [
    {'label': 'All', 'icon': Icons.all_inbox},
    {'label': 'Pending', 'icon': Icons.hourglass_bottom},
    {'label': 'Paid', 'icon': Icons.attach_money},
    {'label': 'Shipped', 'icon': Icons.local_shipping},
    {'label': 'Cancelled', 'icon': Icons.cancel},
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      sellerId = user.uid;
    } else {
      FirebaseAuth.instance.authStateChanges().first.then((u) {
        if (mounted && u != null) {
          setState(() => sellerId = u.uid);
        }
      });
    }
  }

  Widget _buildOrderList() {
    if (sellerId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<MyOrder>>(
      stream: orderController.getOrdersForSeller(sellerId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data ?? [];

        final Map<String, int> statusCounts = {
          'All': allOrders.length,
          'Pending': allOrders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length,
          'Paid': allOrders
              .where((o) => o.status.toLowerCase() == 'paid')
              .length,
          'Shipped': allOrders
              .where((o) => o.status.toLowerCase() == 'shipped')
              .length,
          'Cancelled': allOrders
              .where((o) => o.status.toLowerCase() == 'cancelled')
              .length,
        };

        final filteredOrders = allOrders.where((order) {
          final matchesSearch =
              (order.productName.toLowerCase()).contains(searchQuery) ||
              (order.buyerFirstName?.toLowerCase() ?? '')
                  .contains(searchQuery) ||
              (order.buyerLastName?.toLowerCase() ?? '')
                  .contains(searchQuery);

          final matchesTab = selectedTabIndex == 0 ||
              (order.status.toLowerCase()) ==
                  tabs[selectedTabIndex]['label'].toLowerCase();

          return matchesSearch && matchesTab;
        }).toList();

        if (allOrders.isEmpty) {
          return Column(
            children: [
              const Expanded(
                  child: Center(child: Text("No orders found"))),
              ClaimHistoryDesign.buildTabBar(
                selectedIndex: selectedTabIndex,
                tabs: tabs,
                statusCounts: statusCounts,
                onTap: (i) => setState(() => selectedTabIndex = i),
              ),
            ],
          );
        }

        if (filteredOrders.isEmpty) {
          return Column(
            children: [
              const Expanded(
                  child: Center(child: Text("No matching orders"))),
              ClaimHistoryDesign.buildTabBar(
                selectedIndex: selectedTabIndex,
                tabs: tabs,
                statusCounts: statusCounts,
                onTap: (i) => setState(() => selectedTabIndex = i),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, i) {
                  final o = filteredOrders[i];
                  return ClaimHistoryDesign.buildOrderCard(
                    order: o,
                    onMarkPaid: o.status.toLowerCase() != 'paid'
                        ? () => orderController.updateStatus(
                            sellerId!, o.id, "paid")
                        : null,
                    onShip: o.status.toLowerCase() != 'shipped'
                        ? () => orderController.updateStatus(
                            sellerId!, o.id, "shipped")
                        : null,
                    onCancel: o.status.toLowerCase() != 'cancelled'
                        ? () => orderController.updateStatus(
                            sellerId!, o.id, "cancelled")
                        : null,
                  );
                },
              ),
            ),
            ClaimHistoryDesign.buildTabBar(
              selectedIndex: selectedTabIndex,
              tabs: tabs,
              statusCounts: statusCounts,
              onTap: (i) => setState(() => selectedTabIndex = i),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text("Buyer Orders"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          ClaimHistoryDesign.buildSearchBar(
            onChanged: (value) => setState(() => searchQuery = value),
          ),
          Expanded(child: _buildOrderList()),
        ],
      ),
    );
  }
}
