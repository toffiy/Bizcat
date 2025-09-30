import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import 'sales_chart_design.dart'; // 👈 import the separated chart widget

class SalesReportDesign extends StatelessWidget {
  final List<MyOrder> orders;
  final List<MyOrder> filteredOrders;

  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;

  final Function(int?) onYearChanged;
  final Function(int?) onMonthChanged;
  final Function(int?) onDayChanged;

  final List<int> Function(List<MyOrder>) getAvailableYears;
  final List<int> Function(List<MyOrder>) getAvailableMonths;
  final List<int> Function(List<MyOrder>) getAvailableDays;
  final DateTime Function(dynamic) toDate;

  const SalesReportDesign({
    super.key,
    required this.orders,
    required this.filteredOrders,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onDayChanged,
    required this.getAvailableYears,
    required this.getAvailableMonths,
    required this.getAvailableDays,
    required this.toDate,
  });

  /// ----------------------
  /// FILTERS
  /// ----------------------
  Widget _filters() {
    final years = getAvailableYears(orders);
    final months = getAvailableMonths(orders);
    final days = getAvailableDays(orders);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: selectedYear,
              decoration: const InputDecoration(
                labelText: "Year",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...years.map((y) =>
                    DropdownMenuItem<int?>(value: y, child: Text(y.toString()))),
              ],
              onChanged: onYearChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Month",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...months.map((m) => DropdownMenuItem<int?>(
                    value: m,
                    child: Text(DateFormat.MMMM().format(DateTime(0, m))))),
              ],
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: selectedDay,
              decoration: const InputDecoration(
                labelText: "Day",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...days.map((d) =>
                    DropdownMenuItem<int?>(value: d, child: Text(d.toString()))),
              ],
              onChanged: onDayChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// ----------------------
  /// ORDER TILE
  /// ----------------------
  Widget _orderTile(MyOrder o) {
    final date = toDate(o.timestamp);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        title: Text(
          "${o.buyerFirstName ?? ''} ${o.buyerLastName ?? ''} — ${o.productName}",
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
            if (o.buyerAddress != null && o.buyerAddress!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(o.buyerAddress!,
                        style: const TextStyle(color: Colors.black)),
                  ),
                ],
              ),
          ],
        ),
        trailing: Text(
          "₱${o.totalAmount.toStringAsFixed(2)}",
          style: TextStyle(
            color: o.status.toLowerCase() == "shipped"
                ? Colors.blue
                : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// ----------------------
  /// BUILD METHOD
  /// ----------------------
  @override
  Widget build(BuildContext context) {
    final totalRevenue = filteredOrders.fold<double>(
        0, (sum, order) => sum + order.totalAmount);

    final paidOrdersCount = filteredOrders
        .where((o) =>
            o.status.toLowerCase() == "paid" ||
            o.status.toLowerCase() == "completed")
        .length;

    return Column(
      children: [
        // Stats card
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Total Revenue",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text("₱${totalRevenue.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Paid Orders",
                        style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Text("$paidOrdersCount",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Chart (from separate file)
        SalesChartDesign(
          filteredOrders: filteredOrders,
          selectedYear: selectedYear,
          selectedMonth: selectedMonth,
          selectedDay: selectedDay,
          toDate: toDate,
        ),

        // Filters
        _filters(),

        const Divider(thickness: 1),

        // Orders list
        Expanded(
          child: ListView.builder(
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              return _orderTile(filteredOrders[index]);
            },
          ),
        ),
      ],
    );
  }
}
