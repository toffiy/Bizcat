import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dash_item.dart';
import '../controllers/dashboard_controller.dart';
import '../../auth/Services/auth_service.dart';

/// ----------------------
/// DASHBOARD APP BAR
/// ----------------------
PreferredSizeWidget buildDashboardAppBar({
  required BuildContext context,
  required AuthService authService,
  required DashboardController controller,
}) {
  final currentUser = FirebaseAuth.instance.currentUser;

  return AppBar(
    backgroundColor: Colors.white,
    elevation: 2,
    shadowColor: Colors.black.withOpacity(0.05),
    automaticallyImplyLeading: false,
    title: const Text(
      'Seller Dashboard',
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: Colors.black87,
        letterSpacing: 0.5,
      ),
    ),
    centerTitle: true,
    actions: [
      if (currentUser != null)
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('sellers')
              .doc(currentUser.uid) // 👈 same as ProfilePage
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final imageUrl = (data['profileImageUrl'] ?? '').toString();

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => controller.handleNavigation(context, 'Profile'),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.person,
                            color: Colors.grey, size: 22)
                        : null,
                  ),
                ),
              );
            }
            return const Padding(
              padding: EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            );
          },
        ),
    ],
  );
}

/// ----------------------
/// STAT CARD
/// ----------------------
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool highlight;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.highlight = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: highlight
            ? LinearGradient(
                colors: [iconColor.withOpacity(0.2), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.white, Colors.grey.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Value (number)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: highlight ? 22 : 20,
                      fontWeight: FontWeight.bold,
                      color: highlight ? iconColor : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // ✅ Title (label) slightly bigger
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14, // bumped up from 12
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------
/// QUICK ACTION ITEM
/// ----------------------
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      splashColor: Colors.lightBlue.withOpacity(0.1),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white, // neutral card background
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🔹 Icon container with light blue accent
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                size: 24,
                color: Colors.lightBlue.shade600,
              ),
            ),

            const SizedBox(width: 18),

            // 🔹 Title text
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),

            // 🔹 Trailing arrow
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
