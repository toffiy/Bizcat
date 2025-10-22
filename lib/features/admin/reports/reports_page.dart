import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../reports/report_detail_page.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'under_review':
        return Colors.orange;
      case 'send_warning':
        return Colors.amber;
      case 'suspend_account':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'under_review':
        return "Under Review";
      case 'send_warning':
        return "Warning Sent";
      case 'suspend_account':
        return "Suspended";
      case 'resolved':
        return "Resolved";
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('reports')
            .snapshots(), // no orderBy here to avoid missing-field issues
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports found"));
          }

          final reports = snapshot.data!.docs;

          // Sort manually by createdAt if it exists
          reports.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime); // newest first
            }
            return 0;
          });

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;

              final firstName = data['sellerFirstName'] ?? '';
              final lastName = data['sellerLastName'] ?? '';
              final sellerName = "$firstName $lastName".trim();

              final reason = data['reason'] ?? 'No reason';
              final reviewStatus = data['reviewStatus'] ?? 'under_review';
              final sellerId = data['sellerId'] ?? '';
              final reportId = doc.id;

              // Format createdAt safely
              String createdAtStr = "No date";
              final createdAt = data['createdAt'];
              if (createdAt != null && createdAt is Timestamp) {
                createdAtStr =
                    DateFormat.yMMMd().add_jm().format(createdAt.toDate());
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: Text(
                    sellerName.isNotEmpty ? sellerName : "Unknown Seller",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Reason: $reason"),
                      Text("Created: $createdAtStr"),
                      Text(
                        "Status: ${_statusLabel(reviewStatus)}",
                        style: TextStyle(
                          color: _statusColor(reviewStatus),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportDetailsPage(
                          reportId: reportId,
                          sellerId: sellerId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
