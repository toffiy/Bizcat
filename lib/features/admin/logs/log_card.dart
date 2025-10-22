import 'package:flutter/material.dart';

class LogCard extends StatelessWidget {
  final String action;
  final String sellerId;
  final String sellerName;
  final DateTime? timestamp;

  const LogCard({
    super.key,
    required this.action,
    required this.sellerId,
    required this.sellerName,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          action.toLowerCase().contains('suspended')
              ? Icons.block
              : Icons.check_circle,
          color: action.toLowerCase().contains('suspended')
              ? Colors.red
              : Colors.green,
        ),
        title: Text(
          action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Seller: $sellerName"),
            Text("ID: $sellerId"),
            Text(
              timestamp != null
                  ? "At: ${timestamp.toString()}"
                  : "Pending...",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
