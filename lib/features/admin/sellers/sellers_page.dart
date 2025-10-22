import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seller_card.dart';
import 'seller_detail_page.dart';

class SellersPage extends StatelessWidget {
  const SellersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sellers').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No sellers found"));
        }

        final sellers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: sellers.length,
          itemBuilder: (context, index) {
            final seller = sellers[index];
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
              profileUrl: profileUrl, // pass to card
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
    );
  }
}
