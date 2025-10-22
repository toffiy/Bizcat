import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'log_card.dart'; // ✅ import your LogCard

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('logs')
            //.orderBy('timestamp', descending: true) // requires index
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No logs found"));
          }

          final logs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index].data() as Map<String, dynamic>;

              final action = log['action'] ?? 'Unknown action';
              final sellerId = log['sellerId'] ?? 'Unknown ID';
              final sellerName = log['sellerName'] ?? 'Unknown Seller';
              final ts = log['timestamp'] ?? log['localTimestamp'];
              final timestamp = ts != null ? ts.toDate() : null;

              // ✅ Use LogCard instead of ListTile
              return LogCard(
                action: action,
                sellerId: sellerId,
                sellerName: sellerName,
                timestamp: timestamp,
              );
            },
          );
        },
      ),
    );
  }
}
