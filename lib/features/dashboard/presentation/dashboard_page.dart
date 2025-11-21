import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/order_controller.dart';
import '../../auth/Services/auth_service.dart';
import '../models/dash_item.dart';
import '../models/order.dart';
import '../widgets/dashboard_design.dart';
import '../widgets/notification.dart';
import 'notification_page.dart';

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

  // 🔹 Category input state
  final TextEditingController _categoryController = TextEditingController();
  bool _savingCategory = false;
  bool _isEditingCategory = false; // start disabled until double-tap

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
          // 🔔 Notification Bell
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sellers')
                .doc(sellerId)
                .collection('notifications')
                .snapshots(),
            builder: (context, notifSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(sellerId)
                    .collection('orders')
                    .snapshots(),
                builder: (context, orderSnap) {
                  int unreadNotifCount = 0;
                  int unseenOrderCount = 0;

                  if (notifSnap.hasData) {
                    unreadNotifCount = notifSnap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['read'] != true;
                    }).length;
                  }

                  if (orderSnap.hasData) {
                    unseenOrderCount = orderSnap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['seenNotification'] != true;
                    }).length;
                  }

                  int totalUnread = unreadNotifCount + unseenOrderCount;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                NotificationWindow(sellerId: sellerId),
                          );
                        },
                      ),
                      if (totalUnread > 0)
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
                              '$totalUnread',
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
              );
            },
          ),

          // 👤 Profile Avatar
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sellers')
                .doc(sellerId)
                .snapshots(),
            builder: (context, snapshot) {
              String? imageUrl;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                imageUrl = (data['profileImageUrl'] ?? '').toString();
              }

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    controller.handleNavigation(context, "Profile");
                  },
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl == null || imageUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                ),
              );
            },
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

       StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('sellers')
      .doc(sellerId)
      .snapshots(),
  builder: (context, snapshot) {
    String savedCategory = "";
    if (snapshot.hasData && snapshot.data!.exists) {
      final data = snapshot.data!.data() as Map<String, dynamic>;
      savedCategory = (data['categories'] ?? '').toString();
    }

    final hasCategory = savedCategory.isNotEmpty;

    // Always update controller with Firestore value if not editing
    if (hasCategory && !_isEditingCategory) {
      _categoryController.text = savedCategory;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Catalog Category",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          GestureDetector(
            onDoubleTap: () {
              setState(() => _isEditingCategory = true);
            },
            child: AbsorbPointer(
              absorbing: hasCategory && !_isEditingCategory,
              child: TextField(
                controller: _categoryController,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(15),
                ],
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: (hasCategory && !_isEditingCategory)
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: "e.g. Electronics, Clothing, Food",
                  filled: true,
                  fillColor: (hasCategory && !_isEditingCategory)
                      ? Colors.grey.shade100
                      : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ✅ Show Save button only if:
          // 1. No category exists (empty field), OR
          // 2. User double‑tapped to enable editing
          if (!hasCategory || _isEditingCategory)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  "Save Category",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _savingCategory
                    ? null
                    : () async {
                        final category = _categoryController.text.trim();
                        if (category.isEmpty) return;
                        setState(() => _savingCategory = true);

                        await FirebaseFirestore.instance
                            .collection('sellers')
                            .doc(sellerId)
                            .update({'categories': category});

                        setState(() {
                          _savingCategory = false;
                          _isEditingCategory = false; // back to disabled
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Category saved: $category"),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      },
              ),
            ),
        ],
      ),
    );
  },
),

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

  /// ----------------------
  /// STATS GRID
  /// ----------------------
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

