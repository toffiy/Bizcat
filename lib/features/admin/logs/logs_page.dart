import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String _searchQuery = "";
  String _selectedAction = "all";

  Color _actionColor(String action) {
    if (action.toLowerCase().contains("suspend")) return Colors.red;
    if (action.toLowerCase().contains("reactivate")) return Colors.green;
    return Colors.blueGrey;
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
              hintText: "Search logs...",
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
                value: _selectedAction,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                items: const [
                  DropdownMenuItem(value: "all", child: Text("All")),
                  DropdownMenuItem(value: "suspend", child: Text("Suspended")),
                  DropdownMenuItem(value: "reactivate", child: Text("Reactivated")),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedAction = val;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collectionGroup('logs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No logs found"));
          }

          final logs = snapshot.data!.docs;

          // Sort by timestamp
          logs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['timestamp'] ?? aData['localTimestamp'];
            final bTime = bData['timestamp'] ?? bData['localTimestamp'];
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime); // newest first
            }
            return 0;
          });

          // Apply search + filter
          final filteredLogs = logs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final action = (data['action'] ?? '').toString().toLowerCase();

            final sellerName = (data['sellerName'] ?? '').toString().toLowerCase();
            final sellerId = (data['sellerId'] ?? '').toString().toLowerCase();
            final buyerName = (data['buyerName'] ?? '').toString().toLowerCase();
            final buyerId = (data['buyerId'] ?? '').toString().toLowerCase();

            final matchesSearch = _searchQuery.isEmpty ||
                action.contains(_searchQuery) ||
                sellerName.contains(_searchQuery) ||
                sellerId.contains(_searchQuery) ||
                buyerName.contains(_searchQuery) ||
                buyerId.contains(_searchQuery);

            final matchesFilter = _selectedAction == "all" ||
                (_selectedAction == "suspend" && action.contains("suspend")) ||
                (_selectedAction == "reactivate" && action.contains("reactivate"));

            return matchesSearch && matchesFilter;
          }).toList();

          if (filteredLogs.isEmpty) {
            return const Center(child: Text("No matching logs"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredLogs.length,
            itemBuilder: (context, index) {
              final log = filteredLogs[index].data() as Map<String, dynamic>;

              final action = log['action'] ?? 'Unknown action';

              // 🔹 Detect whether this is a buyer log or seller log
              final bool isBuyerLog = log.containsKey('buyerId') || log.containsKey('buyerName');
              final String id = isBuyerLog
                  ? (log['buyerId'] ?? 'Unknown ID')
                  : (log['sellerId'] ?? 'Unknown ID');
              final String name = isBuyerLog
                  ? (log['buyerName'] ?? 'Unknown Buyer')
                  : (log['sellerName'] ?? 'Unknown Seller');

              final ts = log['timestamp'] ?? log['localTimestamp'];
              final timestamp = ts != null && ts is Timestamp ? ts.toDate() : null;

              final timeStr = timestamp != null
                  ? DateFormat.yMMMd().add_jm().format(timestamp)
                  : "No date";

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: _actionColor(action).withOpacity(0.15),
                    child: Icon(Icons.history, color: _actionColor(action)),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Action: $action",
                            style: const TextStyle(fontSize: 14)),
                        Text("${isBuyerLog ? "Buyer" : "Seller"} ID: $id",
                            style: const TextStyle(fontSize: 13)),
                        Text("Time: $timeStr",
                            style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
