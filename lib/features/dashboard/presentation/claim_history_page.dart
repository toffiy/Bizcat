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
    {'label': 'Completed', 'icon': Icons.local_shipping}, // maps to shipped
    {'label': 'Cancelled', 'icon': Icons.cancel},
  ];

  final Map<String, String> statusMap = {
    'All': 'all',
    'Pending': 'pending',
    'Paid': 'paid',
    'Completed': 'shipped', // ✅ Completed → shipped
    'Cancelled': 'cancelled',
  };

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

  /// 🔹 Confirmation dialog before status change
  void _confirmStatusChange(MyOrder order, String newStatus) {
    if (newStatus.toLowerCase() == 'paid') {
      // ✅ Payment method choice
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Select Payment Method'),
            content: const Text('How was this order paid?'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await orderController.updateStatus(
                    sellerId!,
                    order.id,
                    newStatus,
                    paymentMethod: 'Cash',
                  );
                  _showSnack('Order marked as PAID (Cash)');
                },
                child: const Text('Cash'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await orderController.updateStatus(
                    sellerId!,
                    order.id,
                    newStatus,
                    paymentMethod: 'GCash',
                  );
                  _showSnack('Order marked as PAID (GCash)');
                },
                child: const Text('GCash'),
              ),
            ],
          );
        },
      );
    } else {
      // ✅ Default confirmation for other statuses
      showDialog(
        context: context,
        builder: (context) {
          String message;
          if (newStatus.toLowerCase() == 'shipped') {
            message = 'Are you sure you want to mark this order as complete?';
          } else if (newStatus.toLowerCase() == 'cancelled') {
            message =
                'Are you sure you want to cancel this order?\nStock will be restored automatically.';
          } else {
            message = 'Are you sure you want to mark this order as "$newStatus"?';
          }

          return AlertDialog(
            title: const Text('Confirm Action'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () async {
                  Navigator.pop(context);
                  await orderController.updateStatus(
                    sellerId!,
                    order.id,
                    newStatus,
                  );

                  if (newStatus.toLowerCase() == 'cancelled') {
                    _showSnack(
                        'Order cancelled.');
                  } else {
                    _showSnack('Order marked as $newStatus.');
                  }
                },
                child: const Text('Yes'),
              ),
            ],
          );
        },
      );
    }
  }

  /// 🔹 Snackbar feedback
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
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

        // ✅ Badge counts only for unseen orders
        final Map<String, int> statusCounts = {
          'All': allOrders
              .where((o) =>
                  o.status.toLowerCase() != 'cancelled' && !o.seenBySeller)
              .length,
          'Pending': allOrders
              .where((o) =>
                  o.status.toLowerCase() == 'pending' && !o.seenBySeller)
              .length,
          'Paid': allOrders
              .where((o) => o.status.toLowerCase() == 'paid' && !o.seenBySeller)
              .length,
          'Completed': allOrders
              .where((o) => o.status.toLowerCase() == 'shipped' && !o.seenBySeller)
              .length,
          'Cancelled': allOrders
              .where((o) =>
                  o.status.toLowerCase() == 'cancelled' && !o.seenBySeller)
              .length,
        };

        // ✅ Filter orders for current tab
        final filteredOrders = allOrders.where((order) {
          final matchesSearch =
              (order.productName.toLowerCase()).contains(searchQuery) ||
              (order.buyerFirstName?.toLowerCase() ?? '')
                  .contains(searchQuery) ||
              (order.buyerLastName?.toLowerCase() ?? '')
                  .contains(searchQuery);

          if (selectedTabIndex == 0) {
            return matchesSearch && order.status.toLowerCase() != 'cancelled';
          }

          final tabLabel = tabs[selectedTabIndex]['label'] as String;
          final mappedStatus = statusMap[tabLabel]!;
          final matchesTab = (order.status.toLowerCase()) == mappedStatus;

          return matchesSearch && matchesTab;
        }).toList();

        Widget tabBar = ClaimHistoryDesign.buildTabBar(
          selectedIndex: selectedTabIndex,
          tabs: tabs,
          statusCounts: statusCounts,
          clearedTabs: {},
          onTap: (i) async {
            setState(() {
              selectedTabIndex = i;
            });

            // ✅ Mark orders in this tab as seen
            final tabLabel = tabs[i]['label'] as String;
            final mappedStatus = statusMap[tabLabel]!;
            try {
              final orders =
                  await orderController.getOrdersOnce(sellerId!, mappedStatus);
              await orderController.markOrdersAsSeenBatch(sellerId!, orders);
            } catch (e) {
              debugPrint("Error marking orders as seen: $e");
            }
          },
        );

        if (allOrders.isEmpty) {
          return Column(
            children: [
              const Expanded(child: Center(child: Text("No orders found"))),
              tabBar,
            ],
          );
        }

        if (filteredOrders.isEmpty) {
          return Column(
            children: [
              const Expanded(child: Center(child: Text("No matching orders"))),
              tabBar,
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
                  final status = o.status.toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      orderController.markAsSeen(sellerId!, o.id);
                    },
                    child: Container(
                      key: ValueKey(o.id),
                      color: o.seenBySeller
                          ? Colors.white
                          : Colors.yellow.shade50,
                      child: ClaimHistoryDesign.buildOrderCard(
                        order: o,
                        hideIfCancelled: selectedTabIndex == 0,
                        onMarkPaid: status == 'pending'
                            ? () => _confirmStatusChange(o, 'paid')
                            : null,
                        onShip: status == 'paid'
                            ? () => _confirmStatusChange(o, 'shipped')
                            : null,
                        onCancel: (status == 'pending' ||
                                status == 'paid' ||
                                status == 'shipped')
                            ? () => _confirmStatusChange(o, 'cancelled')
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            tabBar,
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
