import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../sellers/seller_detail_page.dart';
import '../sellers/buyer_detail_page.dart';

class ReportDetailsPage extends StatefulWidget {
  final String reportId;
  final String userId; // sellerId or buyerId
  final String role;   // "Seller" or "Buyer"

  // ❌ remove const, because arguments are runtime values
  ReportDetailsPage({
    super.key,
    required this.reportId,
    required this.userId,
    required this.role,
  });

  @override
  State<ReportDetailsPage> createState() => _ReportDetailsPageState();
}

class _ReportDetailsPageState extends State<ReportDetailsPage> {
  bool actionTaken = false;

  Future<void> _confirmAndUpdateStatus(
    BuildContext context,
    String newStatus,
    String message,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Action"),
        content: Text("Are you sure you want to $message?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reportRef = FirebaseFirestore.instance
          .collection(widget.role == 'Seller' ? 'sellers' : 'buyers')
          .doc(widget.userId)
          .collection('reports')
          .doc(widget.reportId);

      final reportSnap = await reportRef.get();
      final reportData = reportSnap.data() as Map<String, dynamic>? ?? {};
      final reason = reportData['reason'] ?? 'No reason provided';

      await reportRef.update({'reviewStatus': newStatus});

      if (newStatus == "send_warning") {
        final notificationsRef = FirebaseFirestore.instance
            .collection(widget.role == 'Seller' ? 'sellers' : 'buyers')
            .doc(widget.userId)
            .collection('notifications');

        await notificationsRef.add({
          'type': newStatus,
          'title': "Account Warning",
          'message':
              "Your account has received a warning due to: $reason. Please review and take corrective action.",
          'reason': reason,
          'reportId': widget.reportId,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report updated to $newStatus")),
      );

      setState(() {
        actionTaken = true;
      });
    }
  }

  Future<void> _confirmEscalate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Suspension"),
        content: const Text(
            "Are you sure you want to suspend this account? This will update their status to 'suspended'."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Suspend"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection(widget.role == 'Seller' ? 'sellers' : 'buyers')
          .doc(widget.userId)
          .collection('reports')
          .doc(widget.reportId)
          .update({'reviewStatus': 'suspend_account'});

      await FirebaseFirestore.instance
          .collection(widget.role == 'Seller' ? 'sellers' : 'buyers')
          .doc(widget.userId)
          .update({'status': 'suspended'});

      if (!mounted) return;
      setState(() {
        actionTaken = true;
      });

      if (widget.role == 'Seller') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SellerDetailPage(sellerId: widget.userId),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BuyerDetailPage(buyerId: widget.userId),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportRef = FirebaseFirestore.instance
        .collection(widget.role == 'Seller' ? 'sellers' : 'buyers')
        .doc(widget.userId)
        .collection('reports')
        .doc(widget.reportId);

    return Scaffold(
      appBar: AppBar(title: const Text("Report Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: reportRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Report not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final sellerName =
              "${data['sellerFirstName'] ?? ''} ${data['sellerLastName'] ?? ''}".trim();
          final reason = data['reason'] ?? 'No reason';
          final description = data['description'] ?? 'No description';

          String buyerName = "Unknown Buyer";
          if (data.containsKey('buyerFirstName') ||
              data.containsKey('buyerLastName')) {
            buyerName =
                "${data['buyerFirstName'] ?? ''} ${data['buyerLastName'] ?? ''}".trim();
          } else if (data['buyerName'] != null) {
            buyerName = data['buyerName'];
          }
          final buyerEmail = data['buyerEmail'] ?? 'No email';

          final reviewStatus = data['reviewStatus'] ?? 'under_review';
          final evidence = List<String>.from(data['evidence'] ?? []);

          String createdAtStr = "No date";
          final createdAt = data['createdAt'];
          if (createdAt != null && createdAt is Timestamp) {
            createdAtStr =
                DateFormat.yMMMd().add_jm().format(createdAt.toDate());
          }

          String statusLabel;
          Color statusColor;
          switch (reviewStatus) {
            case 'under_review':
              statusLabel = "Under Review";
              statusColor = Colors.orange;
              break;
            case 'send_warning':
              statusLabel = "Warning Sent";
              statusColor = Colors.amber;
              break;
            case 'suspend_account':
              statusLabel = "Suspended";
              statusColor = Colors.red;
              break;
            case 'resolved':
              statusLabel = "Resolved";
              statusColor = Colors.green;
              break;
            default:
              statusLabel = reviewStatus;
              statusColor = Colors.grey;
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.blue),
                    title: Text(
                      sellerName.isEmpty ? "Unknown User" : sellerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Buyer Name: $buyerName"),
                        Text("Buyer Email: $buyerEmail"),
                        Text("Time: $createdAtStr"),
                        Text(
                          "Status: $statusLabel",
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Text("Reason:",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700])),
                const SizedBox(height: 4),
                Text(reason,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                Text("Description:",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description,
                    style: const TextStyle(fontSize: 18, height: 1.4)),
                const SizedBox(height: 24),

                if (evidence.isNotEmpty) ...[
                  const Text("Evidence:",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                                            children: evidence.map((url) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  body: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Center(
                                      child: Hero(
                                        tag: url,
                                        child: Image.network(
                                          url,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: url,
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 160,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // 🔹 Action buttons
                if (reviewStatus == 'under_review') ...[
                  ElevatedButton.icon(
                    onPressed: () => _confirmAndUpdateStatus(
                      context,
                      'send_warning',
                      'send a warning',
                    ),
                    icon: const Icon(Icons.warning, color: Colors.white),
                    label: const Text("Send Warning"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _confirmEscalate(context),
                    icon: const Icon(Icons.person_off, color: Colors.white),
                    // ⚠️ remove const here, widget.role is runtime
                    label: Text("Suspend ${widget.role}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],

                if ((reviewStatus == 'send_warning' ||
                        reviewStatus == 'suspend_account') &&
                    reviewStatus != 'resolved') ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _confirmAndUpdateStatus(
                      context,
                      'resolved',
                      'mark this report as resolved',
                    ),
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text("Mark as Resolved"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

                      