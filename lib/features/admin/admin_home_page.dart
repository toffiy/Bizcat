import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Admin tabs
import 'sellers/users_page.dart';
import 'reports/reports_page.dart';
import 'logs/logs_page.dart';
import 'settings/admin_settings_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    "Dashboard",
    "Manage Accounts",
    "Customer Reports",
    "Audit Logs",
    "Admin Settings",
  ];

  late final List<Widget> _pages = [
    const AdminDashboardPage(),
    UsersPage(),
    ReportsPage(),
    LogsPage(),
    AdminSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex])),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Logs'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

/// =======================
/// DASHBOARD TAB WIDGET
/// =======================
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  /// Count top-level docs (sellers or buyers)
  Stream<int> _countDocs(String collection, [String? field, String? value]) {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection(collection);
    if (field != null && value != null) {
      query = query.where(field, isEqualTo: value);
    }
    return query.snapshots().map((snap) => snap.size);
  }

  /// ✅ Count reports across all sellers
  Stream<int> _countReports([String? status]) {
    Query query = FirebaseFirestore.instance.collectionGroup('reports');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    return query.snapshots().map((snap) => snap.size);
  }

  /// ✅ Count logs across all sellers
  Stream<int> _countLogs() {
    return FirebaseFirestore.instance
        .collectionGroup('logs')
        .snapshots()
        .map((snap) => snap.size);
  }

  Widget _buildMetricCard({
    required String title,
    required String purpose,
    required IconData icon,
    required Stream<int> stream,
    required Color color,
    required Widget dialogContent,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(title),
                content: SizedBox(width: 400, height: 300, child: dialogContent),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$count",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    purpose,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Sellers list
  Widget _buildAllSellersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sellers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No sellers found"));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.store),
              title: Text("${data['firstName']} ${data['lastName']}"),
              subtitle: Text(data['email'] ?? ''),
              trailing: Text(data['status'] ?? 'unknown'),
            );
          },
        );
      },
    );
  }

  /// Buyers list
  Widget _buildAllBuyersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('buyers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No buyers found"));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text("${data['firstName']} ${data['lastName']}"),
              subtitle: Text(data['email'] ?? ''),
              trailing: Text(data['status'] ?? 'active'),
            );
          },
        );
      },
    );
  }

  /// Suspended Accounts list (sellers + buyers)
  Widget _buildSuspendedAccountsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('users') // if you store both sellers & buyers under "users"
          .where('status', isEqualTo: 'suspended')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No suspended accounts found"));
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text("${data['firstName']} ${data['lastName']}"),
              subtitle: Text(data['email'] ?? ''),
              trailing: Text(
                data['status'] ?? 'unknown',
                style: const TextStyle(color: Colors.red),
              ),
            );
          },
        );
      },
    );
  }

    /// Reports list
  Widget _buildReportsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('reports')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No reports found"));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final sellerEmail = data['sellerEmail'] ?? 'Unknown Seller';
            final sellerId = data['sellerId'] ?? '';
            final reason = data['reason'] ?? 'Report';
            final description = data['description'] ?? '';

            return ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: Text(reason),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description),
                  Text("Reported Seller: $sellerEmail",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("ID: $sellerId",
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Logs list
  Widget _buildLogsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('logs')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text("No logs found"));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final action = data['action'] ?? 'Log Entry';
            final user = data['user'] ?? '';
            final sellerEmail = data['sellerName'] ?? 'Unknown Seller';

            // Build a richer subtitle
            String subtitleText = user;
            if (action.toLowerCase().contains('suspend') ||
                action.toLowerCase().contains('ban')) {
              subtitleText = "Seller banned: $sellerEmail";
            } else if (action.toLowerCase().contains('unban') ||
                action.toLowerCase().contains('unsuspend')) {
              subtitleText = "Seller unbanned: $sellerEmail";
            } else {
              subtitleText = "$user • Seller: $sellerEmail";
            }

            return ListTile(
              leading: Icon(
                action.toLowerCase().contains('suspend') ||
                        action.toLowerCase().contains('ban')
                    ? Icons.block
                    : Icons.check_circle,
                color: action.toLowerCase().contains('suspend') ||
                        action.toLowerCase().contains('ban')
                    ? Colors.red
                    : Colors.green,
              ),
              title: Text(action),
              subtitle: Text(subtitleText),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(13),
      crossAxisSpacing: 5,
      mainAxisSpacing: 5,
      children: [
        _buildMetricCard(
          title: "Total Sellers",
          purpose: "All registered sellers in the system",
          icon: Icons.store,
          stream: _countDocs("sellers"),
          color: Colors.blue,
          dialogContent: _buildAllSellersList(),
        ),
        _buildMetricCard(
          title: "Total Buyers",
          purpose: "All registered buyers in the system",
          icon: Icons.people,
          stream: _countDocs("buyers"),
          color: Colors.green,
          dialogContent: _buildAllBuyersList(),
        ),
        _buildMetricCard(
          title: "Suspended Accounts",
          purpose: "Accounts restricted due to violations",
          icon: Icons.block,
          stream: _countDocs("sellers", "status", "suspended"),
          color: Colors.red,
          dialogContent: _buildSuspendedAccountsList(),
        ),
        _buildMetricCard(
          title: "Recent Reports",
          purpose: "Latest customer reports submitted",
          icon: Icons.report,
          stream: _countReports(),
          color: Colors.orange,
          dialogContent: _buildReportsList(),
        ),
        _buildMetricCard(
          title: "Recent Logs",
          purpose: "Latest admin and system activities",
          icon: Icons.history,
          stream: _countLogs(),
          color: Colors.teal,
          dialogContent: _buildLogsList(),
        ),
      ],
    );
  }
}
