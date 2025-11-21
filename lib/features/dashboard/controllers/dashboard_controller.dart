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
import '../presentation/under_review_screen.dart';

class DashboardController {
  /// Expose reactive values for the UI
  final ValueNotifier<String?> sellerStatus = ValueNotifier<String?>(null);
  final ValueNotifier<int> reportCount = ValueNotifier<int>(0);

  /// ----------------------
  /// Monitor Seller Status & Reports
  /// ----------------------
  void monitorSellerStatus(BuildContext context, String sellerId) {
    final sellerDoc =
        FirebaseFirestore.instance.collection('sellers').doc(sellerId);

    // Listen to seller status
    sellerDoc.snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'];
        sellerStatus.value = status; // auto refresh via ValueNotifier

        debugPrint("Seller status: $status");

        if (status == 'suspended') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BlockedScreen()),
                (route) => false,
              );
            }
          });
        }
      }
    });

    // Listen to reports count (only those without reviewStatus)
    sellerDoc.collection('reports').snapshots().listen((querySnapshot) {
    final docs = querySnapshot.docs;
    final count = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['reviewStatus'] == null; // catches missing or null
    }).length;

    reportCount.value = count;
    debugPrint("Reports without reviewStatus: $count");

    if (count > 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const UnderReviewScreen()),
            (route) => false,
          );
        }
      });
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
