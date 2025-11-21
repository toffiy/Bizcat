import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../reports/report_detail_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _searchQuery = "";
  String _selectedStatus = "all";

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        titleSpacing: 0,
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            style: const TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              hintText: "Search reports...",
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.toLowerCase();
              });
            },
          ),
        ),
        actions: [
          Container(
            height: 38,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedStatus,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All")),
                  DropdownMenuItem(value: "under_review", child: Text("Under Review")),
                  DropdownMenuItem(value: "send_warning", child: Text("Warning Sent")),
                  DropdownMenuItem(value: "suspend_account", child: Text("Suspended")),
                  DropdownMenuItem(value: "resolved", child: Text("Resolved")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedStatus = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('reports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports found"));
          }

          final reports = snapshot.data!.docs;

          // Sort unresolved first, resolved last, newest first
          reports.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aStatus = (aData['reviewStatus'] ?? 'under_review').toString();
            final bStatus = (bData['reviewStatus'] ?? 'under_review').toString();

            if (aStatus == 'resolved' && bStatus != 'resolved') return 1;
            if (aStatus != 'resolved' && bStatus == 'resolved') return -1;

            final aTime = aData['createdAt'];
            final bTime = bData['createdAt'];
            if (aTime is Timestamp && bTime is Timestamp) {
              return bTime.compareTo(aTime);
            }
            return 0;
          });

          // Apply search + filter
          final filteredReports = reports.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final reason = (data['reason'] ?? '').toString().toLowerCase();
            final status = (data['reviewStatus'] ?? 'under_review').toString();

            final matchesSearch = _searchQuery.isEmpty ||
                name.contains(_searchQuery) ||
                reason.contains(_searchQuery);

            final matchesStatus =
                _selectedStatus == "all" || status == _selectedStatus;

            return matchesSearch && matchesStatus;
          }).toList();

          if (filteredReports.isEmpty) {
            return const Center(child: Text("No matching reports"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredReports.length,
            itemBuilder: (context, index) {
              final doc = filteredReports[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unknown';
              final reason = data['reason'] ?? 'No reason';
              final reviewStatus = data['reviewStatus'] ?? 'under_review';
              final userId = data['id'] ?? '';
              final reportId = doc.id;

              String createdAtStr = "No date";
              final createdAt = data['createdAt'];
              if (createdAt != null && createdAt is Timestamp) {
                createdAtStr = DateFormat.yMMMd().add_jm().format(createdAt.toDate());
              }

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(reviewStatus).withOpacity(0.15),
                    child: Icon(Icons.report, color: _statusColor(reviewStatus)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Reason: $reason", style: const TextStyle(fontSize: 14)),
                        Text("Date: $createdAtStr", style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(reviewStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusLabel(reviewStatus),
                            style: TextStyle(
                              color: _statusColor(reviewStatus),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReportDetailsPage(
                                reportPath: doc.reference.path, // 👈 pass full path instead of just ID
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
