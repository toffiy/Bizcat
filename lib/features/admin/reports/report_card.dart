import 'package:flutter/material.dart';

class ReportCard extends StatelessWidget {
  final String sellerId;
  final String reason;
  final String description;
  final String category;
  final List<dynamic> evidence;
  final String status;
  final DateTime? createdAt;

  const ReportCard({
    super.key,
    required this.sellerId,
    required this.reason,
    required this.description,
    required this.category,
    required this.evidence,
    required this.status,
    this.createdAt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: Icon(
          status == 'pending' ? Icons.report_problem : Icons.check_circle,
          color: status == 'pending' ? Colors.orange : Colors.green,
        ),
        title: Text("Report: $category"),
        subtitle: Text("Seller ID: $sellerId\nReason: $reason"),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(description),
          ),
          if (evidence.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: evidence.map((url) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.network(url, width: 120, fit: BoxFit.cover),
                  );
                }).toList(),
              ),
            ),
          Text(
            createdAt != null
                ? "Submitted: ${createdAt.toString()}"
                : "No timestamp",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
