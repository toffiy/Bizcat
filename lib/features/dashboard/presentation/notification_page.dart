import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../controllers/order_controller.dart';
import '../models/order.dart';

class NotificationWindow extends StatelessWidget {
  final String sellerId;
  final OrderController orderController = OrderController();

  NotificationWindow({super.key, required this.sellerId});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 360,
        height: 480,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Notifications",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      // 🔹 Mark all notifications as read
                      final notifSnap = await FirebaseFirestore.instance
                          .collection('sellers')
                          .doc(sellerId)
                          .collection('notifications')
                          .get();

                      for (var doc in notifSnap.docs) {
                        doc.reference.update({'read': true});
                      }

                      // 🔹 Mark all orders' seenNotification = true
                      final orderSnap = await FirebaseFirestore.instance
                          .collection('sellers')
                          .doc(sellerId)
                          .collection('orders')
                          .get();

                      for (var doc in orderSnap.docs) {
                        doc.reference.update({'seenNotification': true});
                      }
                    },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text("Mark all read"),
                  ),
                ],
              ),
            ),

            // Combined feed
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(sellerId)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, notifSnap) {
                  return StreamBuilder<List<MyOrder>>(
                    stream: orderController.getOrdersForSeller(sellerId),
                    builder: (context, orderSnap) {
                      if (!notifSnap.hasData || !orderSnap.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      // Map notifications
                      final notifDocs = notifSnap.data!.docs.map((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return {
                          'id': d.id,
                          'title': data['title'] ?? 'Notification',
                          'message': data['message'] ?? '',
                          'createdAt':
                              (data['createdAt'] as Timestamp?)?.toDate(),
                          'read': data['read'] == true,
                          'type': 'notification',
                          'ref': d.reference,
                        };
                      });

                      // Map orders
                      final orderDocs = orderSnap.data!.map((o) {
                        final seen = o.seenNotification == true; // null → false
                        return {
                          'id': o.id,
                          'title': 'New Order',
                          'message':
                              '${o.buyerFirstName ?? ''} ${o.buyerLastName ?? ''} ordered ${o.quantity} × ${o.productName}',
                          'createdAt': o.timestamp,
                          'read': seen,
                          'type': 'order',
                          'ref': o.id,
                        };
                      });

                      // Merge and sort
                      final all = [...notifDocs, ...orderDocs];
                      all.sort((a, b) => (b['createdAt'] ?? DateTime(0))
                          .compareTo(a['createdAt'] ?? DateTime(0)));

                      if (all.isEmpty) {
                        return const Center(
                          child: Text("No notifications or orders",
                              style: TextStyle(color: Colors.grey)),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: all.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = all[index];
                          final isRead = item['read'] == true;
                          final createdAt = item['createdAt'] as DateTime?;

                          return InkWell(
                            onTap: () {
                              if (item['type'] == 'notification') {
                                item['ref'].update({'read': true});
                              } else if (item['type'] == 'order') {
                                orderController.markOrderSeenInNotification(
                                    sellerId, item['ref']);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isRead
                                    ? Colors.white
                                    : Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isRead
                                      ? Colors.grey.shade200
                                      : Colors.blue.shade100,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    item['type'] == 'order'
                                        ? Icons.shopping_cart
                                        : Icons.notifications,
                                    color: isRead ? Colors.grey : Colors.blue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(item['title'],
                                                style: TextStyle(
                                                  fontWeight: isRead
                                                      ? FontWeight.normal
                                                      : FontWeight.bold,
                                                  fontSize: 15,
                                                )),
                                            if (!isRead)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade400,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  "NEW",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item['message'],
                                            style: const TextStyle(
                                                color: Colors.black87)),
                                        if (createdAt != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              timeago.format(createdAt),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
