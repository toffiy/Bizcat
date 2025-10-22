import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import pages with aliases to avoid naming conflicts
import '../presentation/product_catalog_page.dart';
import '../presentation/Customer_List_Page.dart';
import '../presentation/Claim_history_Page.dart' as claim;
import '../presentation/sales_report_page.dart' as sales;
import '../presentation/live_control_page.dart';
import '../presentation/profile_page.dart';
import '../presentation/qr_generator_page.dart';
import '../services/seller_service.dart';
import '../presentation/blocked_screen.dart';

class DashboardController {
  /// ----------------------
  /// Monitor Seller Status
  /// ----------------------
  /// Call this in DashboardPage.initState()
      void monitorSellerStatus(BuildContext context, String sellerId) {
      FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .snapshots()
          .listen((doc) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status']; // ✅ matches your Firestore field

          debugPrint("Seller status: $status"); // 👀 log to console for debugging

          if (status == 'suspended') {
            // Delay navigation until after build to avoid context issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BlockedScreen()),
                (route) => false,
              );
            });
          }
        }
      });
    }


  /// ----------------------
  /// Handle Navigation
  /// ----------------------
  void handleNavigation(BuildContext context, String title) {
    switch (title) {
      case 'Product Catalog':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProductCatalogPage()),
        );
        break;

      case 'Customer List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerListPage()),
        );
        break;

      case 'QR Code Generator':
        bool isNewAccount = true;

        SellerService.getSellerId().then((sellerId) {
          if (sellerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QRGeneratorPage(
                  isNewAccount: isNewAccount,
                  sellerId: sellerId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seller ID not found')),
            );
          }
        });
        break;

      case 'Claim History':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => claim.ClaimHistoryPage()),
        );
        break;

      case 'Sales Reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => sales.SalesReportPage()),
        );
        break;

      case 'Live Control':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LiveControlPage()),
        );
        break;

      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }
}
