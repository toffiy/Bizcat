import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart'; // ✅ Needed for PdfPageFormat & PdfColors
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/order_controller.dart';
import '../models/order.dart';
import '../widgets/sales_report_design.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final orderController = OrderController();
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  int? selectedYear;
  int? selectedMonth;
  int? selectedDay;

  DateTime _toDate(dynamic ts) {
    if (ts is Timestamp) return ts.toDate();
    if (ts is DateTime) return ts;
    throw ArgumentError('Invalid timestamp type');
  }

  String _formatDate(dynamic ts) {
    final date = _toDate(ts);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<int> _getAvailableYears(List<MyOrder> orders) {
    final years = orders.map((o) => _toDate(o.timestamp).year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  List<int> _getAvailableMonths(List<MyOrder> orders) {
    if (selectedYear == null) return [];
    final months = orders
        .where((o) => _toDate(o.timestamp).year == selectedYear)
        .map((o) => _toDate(o.timestamp).month)
        .toSet()
        .toList()
      ..sort();
    return months;
  }

  List<int> _getAvailableDays(List<MyOrder> orders) {
    if (selectedYear == null || selectedMonth == null) return [];
    final days = orders
        .where((o) =>
            _toDate(o.timestamp).year == selectedYear &&
            _toDate(o.timestamp).month == selectedMonth)
        .map((o) => _toDate(o.timestamp).day)
        .toSet()
        .toList()
      ..sort();
    return days;
  }

  List<MyOrder> _filterOrders(List<MyOrder> orders) {
    return orders.where((o) {
      final date = _toDate(o.timestamp);
      final status = o.status.toLowerCase();
      final isFulfilled = status == "paid" || status == "shipped";
      if (!isFulfilled) return false;
      if (selectedYear != null && date.year != selectedYear) return false;
      if (selectedMonth != null && date.month != selectedMonth) return false;
      if (selectedDay != null && date.day != selectedDay) return false;
      return true;
    }).toList();
  }

  Future<void> _exportToPDF({
    required List<MyOrder> orders,
    required double totalRevenue,
    required double avgSale,
    required int completedCount,
    required int pendingCount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Sales Report',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text('Total Revenue: PHP ${totalRevenue.toStringAsFixed(2)}'),
          pw.Text('Average Sale: PHP ${avgSale.toStringAsFixed(2)}'),
          pw.Text('Completed Orders: $completedCount'),
          pw.Text('Pending Orders: $pendingCount'),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Date', 'Product', 'Qty', 'Total'],
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            headerStyle: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 11),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(2),
            },
            data: orders.map((o) => [
              _formatDate(o.timestamp),
              o.productName,
              o.quantity.toString(),
              'PHP ${o.totalAmount.toStringAsFixed(2)}'
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales Report"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<List<MyOrder>>(
        stream: orderController.getOrdersForSeller(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const Center(child: Text("No sales data"));
          }

          final filtered = _filterOrders(orders);

          final totalRevenue = filtered.fold<double>(
            0.0,
            (sum, o) => sum + (o.totalAmount),
          );

          final completedCount = filtered.length;
          final avgSale = completedCount > 0
              ? totalRevenue / completedCount
              : 0.0;

          final pendingCount = orders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length;

          return Column(
            children: [
              Expanded(
                child: SalesReportDesign(
                  orders: orders,
                  filteredOrders: filtered,
                  totalRevenue: totalRevenue,
                  completedCount: completedCount,
                  avgSale: avgSale,
                  pendingCount: pendingCount,
                  selectedYear: selectedYear,
                  selectedMonth: selectedMonth,
                  selectedDay: selectedDay,
                  onYearChanged: (val) {
                    setState(() {
                      selectedYear = val;
                      selectedMonth = null;
                      selectedDay = null;
                    });
                  },
                  onMonthChanged: (val) {
                    setState(() {
                      selectedMonth = val;
                      selectedDay = null;
                    });
                  },
                  onDayChanged: (val) {
                    setState(() {
                      selectedDay = val;
                    });
                  },
                  getAvailableYears: _getAvailableYears,
                  getAvailableMonths: _getAvailableMonths,
                  getAvailableDays: _getAvailableDays,
                  toDate: _toDate,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export to PDF"),
                  onPressed: () {
                    _exportToPDF(
                      orders: filtered,
                      totalRevenue: totalRevenue,
                      avgSale: avgSale,
                      completedCount: completedCount,
                      pendingCount: pendingCount,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
