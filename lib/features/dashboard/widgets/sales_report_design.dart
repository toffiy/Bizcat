import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';

class SalesReportDesign extends StatelessWidget {
  final List<MyOrder> orders;
  final List<MyOrder> filteredOrders;
  final double totalRevenue;
  final int completedCount;
  final double avgSale;
  final int pendingCount;

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
    required this.totalRevenue,
    required this.completedCount,
    required this.avgSale,
    required this.pendingCount,
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

  /// Summary card — only icon has color
  Widget _summaryCard(String label, String value, Color iconColor, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black)),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  /// Filters row
  Widget _filters() {
    final years = getAvailableYears(orders);
    final months = getAvailableMonths(orders);
    final days = getAvailableDays(orders);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: selectedYear,
              hint: const Text("Year"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...years.map((y) => DropdownMenuItem<int?>(value: y, child: Text(y.toString()))),
              ],
              onChanged: onYearChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: selectedMonth,
              hint: const Text("Month"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...months.map((m) => DropdownMenuItem<int?>(
                    value: m, child: Text(DateFormat.MMMM().format(DateTime(0, m))))),
              ],
              onChanged: onMonthChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<int?>(
              isExpanded: true,
              value: selectedDay,
              hint: const Text("Day"),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text("All")),
                ...days.map((d) => DropdownMenuItem<int?>(value: d, child: Text(d.toString()))),
              ],
              onChanged: onDayChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Order list tile — icons in one neutral color
  Widget _orderTile(MyOrder o) {
    final date = toDate(o.timestamp);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          "${o.buyerFirstName ?? ''} ${o.buyerLastName ?? ''} — ${o.productName}",
          style: const TextStyle(color: Colors.black),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (o.buyerPhone != null && o.buyerPhone!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[700]),
                  const SizedBox(width: 4),
                  Text(o.buyerPhone!, style: const TextStyle(color: Colors.black)),
                ],
              ),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 4),
                Text(DateFormat('dd/MM/yyyy').format(date),
                    style: const TextStyle(color: Colors.black)),
              ],
            ),
            if (o.buyerAddress != null && o.buyerAddress!.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
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

  @override
  Widget build(BuildContext context) {
    // Prevent avgSale error by ensuring it's valid
    final safeAvgSale = completedCount > 0 ? avgSale : 0;

    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            _summaryCard("Revenue", "₱${totalRevenue.toStringAsFixed(2)}",
                Colors.green, Icons.attach_money),
            _summaryCard("Sales", "$completedCount",
                Colors.blue, Icons.shopping_cart),
          ],
        ),
        Row(
          children: [
            _summaryCard("Avg Sale", "₱${safeAvgSale.toStringAsFixed(2)}",
                Colors.orange, Icons.analytics),
            _summaryCard("Pending", "$pendingCount",
                Colors.red, Icons.pending_actions),
          ],
        ),

        const Divider(thickness: 1),

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
