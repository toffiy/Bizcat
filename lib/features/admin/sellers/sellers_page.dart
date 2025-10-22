import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_card.dart';
import 'seller_detail_page.dart';

class SellersPage extends StatefulWidget {
  const SellersPage({super.key});

  @override
  State<SellersPage> createState() => _SellersPageState();
}

class _SellersPageState extends State<SellersPage> {
  String _searchQuery = "";
  String _selectedStatus = "all";

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.red;
      default:
        return Colors.grey;
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
              hintText: "Search sellers...",
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
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sellers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No sellers found"));
          }

          final sellers = snapshot.data!.docs;

          // Apply search + filter
          final filteredSellers = sellers.where((doc) {
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

            return matchesSearch && matchesStatus;
          }).toList();

          if (filteredSellers.isEmpty) {
            return const Center(child: Text("No matching sellers"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredSellers.length,
            itemBuilder: (context, index) {
              final seller = filteredSellers[index];
              final data = seller.data() as Map<String, dynamic>;

              final firstName = data['firstName'] ?? '';
              final lastName = data['lastName'] ?? '';
              final name = "$firstName $lastName".trim().isEmpty
                  ? 'Unknown Seller'
                  : "$firstName $lastName";

              final email = data['email'] ?? '';
              final status = data['status'] ?? 'active';
              final profileUrl = data['profileImageUrl'] ?? '';

              return SellerCard(
                id: seller.id,
                name: name,
                email: email,
                status: status,
                profileUrl: profileUrl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerDetailPage(sellerId: seller.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
