import 'package:flutter/material.dart';

// Import pages with aliases to avoid naming conflicts
import '../presentation/product_catalog_page.dart';
import '../presentation/Customer_List_Page.dart';
import '../presentation/Claim_history_Page.dart' as claim;
import '../presentation/sales_report_page.dart' as sales;
import '../presentation/live_control_page.dart';
import '../presentation/profile_page.dart'; // ⬅️ Added import here

class DashboardController {
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

      case 'Profile': // ⬅️ New Profile case
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
    }
  }
}
