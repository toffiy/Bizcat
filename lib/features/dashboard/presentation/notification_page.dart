import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationWindow extends StatelessWidget {
  final String sellerId;
  const NotificationWindow({super.key, required this.sellerId});

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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: const Border(bottom: BorderSide(color: Colors.grey, width: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Notifications",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      final snap = await FirebaseFirestore.instance
                          .collection('sellers')
                          .doc(sellerId)
                          .collection('notifications')
                          .where('read', isEqualTo: false)
                          .get();
                      for (var doc in snap.docs) {
                        doc.reference.update({'read': true});
                      }
                    },
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text("Mark all read"),
                  ),
                ],
              ),
            ),

            // Notifications list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sellers')
                    .doc(sellerId)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.notifications_off, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No notifications",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isRead = data['read'] == true;
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                      return InkWell(
                        onTap: () => doc.reference.update({'read': true}),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isRead ? Colors.grey.shade200 : Colors.blue.shade100,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.notifications,
                                  color: isRead ? Colors.grey : Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['title'] ?? '',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 15,
                                        )),
                                    const SizedBox(height: 4),
                                    Text(data['message'] ?? '',
                                        style: const TextStyle(color: Colors.black87)),
                                    if (createdAt != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          timeago.format(createdAt),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(Icons.fiber_new, color: Colors.red, size: 20),
                                ),
                            ],
                          ),
                        ),
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
