import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import '../models/order.dart';

class PDFExporter {
  static Future<Uint8List> generateSalesReport({
    required List<MyOrder> orders,
    required double totalRevenue,
    required double avgSale,
    required int completedCount,
    required int pendingCount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24))),
          pw.Text('Total Revenue: ₱${totalRevenue.toStringAsFixed(2)}'),
          pw.Text('Average Sale: ₱${avgSale.toStringAsFixed(2)}'),
          pw.Text('Completed Orders: $completedCount'),
          pw.Text('Pending Orders: $pendingCount'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Product', 'Qty', 'Total'],
            data: orders.map((o) => [
              o.timestamp.toString().split(' ')[0],
              o.productName,
              o.quantity.toString(),
              '₱${o.totalAmount.toStringAsFixed(2)}'
            ]).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
