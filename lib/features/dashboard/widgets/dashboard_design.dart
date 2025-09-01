import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dash_item.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/Services/auth_service.dart';

PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required String sellerId,
  required AuthService authService,
  required DashboardController controller,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    title: const Text(
      'Seller Dashboard',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    ),
    centerTitle: true,
    actions: [
      // 🔹 Removed logout button here
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sellers')
            .doc(sellerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            final imageUrl = data['profileImageUrl'];

            return IconButton(
              icon: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              onPressed: () {
                controller.handleNavigation(context, 'Profile');
              },
            );
          } else {
            return IconButton(
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              onPressed: () {
                controller.handleNavigation(context, 'Profile');
              },
            );
          }
        },
      ),
    ],
  );
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardQuickActionItem extends StatelessWidget {
  final DashboardItem item;
  final VoidCallback onTap;

  const DashboardQuickActionItem({
    required this.item,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(item.icon, size: 26, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
