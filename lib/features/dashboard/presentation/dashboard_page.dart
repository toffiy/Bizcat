import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/Services/auth_service.dart';
import '../controllers/order_controller.dart';
import '../models/dash_item.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../widgets/dashboard_design.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../widgets/notification.dart'; // ✅ your top notification helper
import 'notification_page.dart'; // ✅ the popup notification window

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardController controller = DashboardController();
  final AuthService authService = AuthService();
  final OrderController orderController = OrderController();

  final String sellerId = FirebaseAuth.instance.currentUser!.uid;

  final List<DashboardItem> quickActions = [
    DashboardItem(title: 'Product Catalog', icon: Icons.inventory),
    DashboardItem(title: 'Customer List', icon: Icons.people),
    DashboardItem(title: 'QR Code Generator', icon: Icons.qr_code),
    DashboardItem(title: 'Claim History', icon: Icons.history),
    DashboardItem(title: 'Sales Reports', icon: Icons.bar_chart),
    DashboardItem(title: 'Live Control', icon: Icons.live_tv),
  ];

  int _previousOrderCount = 0;
  
  @override
  void initState() {
    super.initState();
    controller.monitorSellerStatus(context, sellerId);
  }


 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          // 🔔 Notification Bell with Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sellers')
                .doc(sellerId)
                .collection('notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => NotificationWindow(sellerId: sellerId),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // 👤 Profile Avatar
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                controller.handleNavigation(context, "Profile");
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.person, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<MyOrder>>(
              stream: orderController.getOrdersForSeller(sellerId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final orders = snapshot.data!;
                  if (_previousOrderCount != 0 &&
                      orders.length > _previousOrderCount) {
                    final newOrder = orders.first;

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      TopNotification.show(
                        context,
                        ' New order from ${newOrder.buyerFirstName}',
                        backgroundColor: Colors.green.shade600,
                      );
                    });
                  }
                  _previousOrderCount = orders.length;
                }
                return _buildStatsGrid(context);
              },
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

  Widget _buildStatsGrid(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      children: [
        _buildAnnualSalesCard(),
        _buildDailySalesCard(),
        _buildPendingOrdersCard(),
        _buildProductsCard(),
      ],
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
        final count = snapshot.hasData
            ? snapshot.data!.docs
                .where((doc) =>
                    (doc['status'] ?? '').toString().trim().toLowerCase() ==
                    'pending')
                .length
            : 0;
        return StatCard(
          title: 'Pending Orders',
          value: '$count',
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
            final status = (order.status ?? '').toString().trim().toLowerCase();
            if (status == 'cancelled') continue;

            final dateTime = order.timestamp is Timestamp
                ? (order.timestamp as Timestamp).toDate()
                : order.timestamp as DateTime;

            if (DateFormat('yyyy-MM-dd').format(dateTime) == today) {
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
            final status = (order.status ?? '').toString().trim().toLowerCase();
            if (status == 'cancelled') continue;

            final dateTime = order.timestamp is Timestamp
                ? (order.timestamp as Timestamp).toDate()
                : order.timestamp as DateTime;

            if (dateTime.year == currentYear) {
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
