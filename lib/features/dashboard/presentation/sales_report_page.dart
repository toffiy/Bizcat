import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

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

          // ✅ Null-safe total revenue calculation
          final totalRevenue = filtered.fold<double>(
            0.0,
            (sum, o) => sum + (o.totalAmount),
          );

          final completedCount = filtered.length;

          // ✅ Always a double
          final avgSale = completedCount > 0
              ? totalRevenue / completedCount
              : 0.0;

          final pendingCount = orders
              .where((o) => o.status.toLowerCase() == 'pending')
              .length;

          return SalesReportDesign(
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
          );
        },
      ),
    );
  }
}
