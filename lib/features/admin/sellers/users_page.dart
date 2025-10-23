import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_card.dart';
import 'seller_detail_page.dart';
import 'buyer_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String _searchQuery = "";
  String _selectedStatus = "all"; // all, active, suspended
  String _selectedRole = "all";   // all, Seller, Buyer

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: _buildSearchBar(),
        actions: [
          _buildRoleFilter(),
          _buildStatusFilter(),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sellers').snapshots(),
        builder: (context, sellerSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('buyers').snapshots(),
            builder: (context, buyerSnap) {
              if (sellerSnap.connectionState == ConnectionState.waiting ||
                  buyerSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!sellerSnap.hasData && !buyerSnap.hasData) {
                return const Center(child: Text("No users found"));
              }

              final sellers = sellerSnap.data?.docs ?? [];
              final buyers = buyerSnap.data?.docs ?? [];

              // Merge into one list with role info
              final allUsers = [
                ...sellers.map((d) => {'doc': d, 'role': 'Seller'}),
                ...buyers.map((d) => {'doc': d, 'role': 'Buyer'}),
              ];

              // Apply search + filters
              final filtered = allUsers.where((entry) {
                final doc = entry['doc'] as QueryDocumentSnapshot;
                final role = entry['role'] as String;
                final data = doc.data() as Map<String, dynamic>;

                final firstName = (data['firstName'] ?? '').toString();
                final lastName = (data['lastName'] ?? '').toString();
                final name = "$firstName $lastName".toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final status = (data['status'] ?? 'active').toString();

                final matchesSearch = _searchQuery.isEmpty ||
                    name.contains(_searchQuery) ||
                    email.contains(_searchQuery);

                final matchesStatus =
                    _selectedStatus == "all" || status == _selectedStatus;

                final matchesRole =
                    _selectedRole == "all" || role == _selectedRole;

                return matchesSearch && matchesStatus && matchesRole;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text("No matching users"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  final doc = entry['doc'] as QueryDocumentSnapshot;
                  final role = entry['role'] as String;
                  final data = doc.data() as Map<String, dynamic>;

                  final firstName = data['firstName'] ?? '';
                  final lastName = data['lastName'] ?? '';
                  final name = "$firstName $lastName".trim().isEmpty
                      ? 'Unknown User'
                      : "$firstName $lastName";
                  final email = data['email'] ?? '';
                  final status = data['status'] ?? 'active';
                  final profileUrl = data['profileImageUrl'] ?? '';

                  return UserCard(
                    id: doc.id,
                    name: name,
                    email: email,
                    status: status,
                    profileUrl: profileUrl,
                    role: role,
                    onTap: () {
                      if (role == 'Seller') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SellerDetailPage(sellerId: doc.id),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuyerDetailPage(buyerId: doc.id),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 🔎 Search bar widget
  Widget _buildSearchBar() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        style: const TextStyle(fontSize: 15),
        decoration: const InputDecoration(
          hintText: "Search ...",
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
    );
  }

  /// 🔎 Role filter dropdown
  Widget _buildRoleFilter() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          items: const [
            DropdownMenuItem(value: "all", child: Text("All Roles")),
            DropdownMenuItem(value: "Seller", child: Text("Seller")),
            DropdownMenuItem(value: "Buyer", child: Text("Buyer")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedRole = val;
              });
            }
          },
        ),
      ),
    );
  }

  /// 🔎 Status filter dropdown
  Widget _buildStatusFilter() {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          items: const [
            DropdownMenuItem(value: "all", child: Text("All Status")),
            DropdownMenuItem(value: "active", child: Text("Active")),
            DropdownMenuItem(value: "suspended", child: Text("Suspended")),
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
    );
  }
}
