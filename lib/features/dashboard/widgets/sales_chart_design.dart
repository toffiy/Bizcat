import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/order.dart';

class SalesChartDesign extends StatelessWidget {
  final List<MyOrder> filteredOrders;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedDay;
  final DateTime Function(dynamic) toDate;

  const SalesChartDesign({
    super.key,
    required this.filteredOrders,
    required this.selectedYear,
    required this.selectedMonth,
    required this.selectedDay,
    required this.toDate,
  });

  String _labelFor(int value) {
    if (selectedDay != null) {
      // Format as 12-hour time with AM/PM
      final dt = DateTime(0, 1, 1, value); // dummy date with given hour
      return DateFormat.j().format(dt); // e.g. "6 PM", "10 AM"
    }
    if (selectedMonth != null) return value.toString();
    if (value >= 1 && value <= 12) {
      return DateFormat.MMM().format(DateTime(0, value));
    }
    return value.toString();
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return "₱${(value / 1000000).toStringAsFixed(1)}M";
    if (value >= 1000) {
      // Show 1.5k style if not a whole multiple of 1000
      final kValue = value / 1000;
      return kValue % 1 == 0
          ? "₱${kValue.toStringAsFixed(0)}k"
          : "₱${kValue.toStringAsFixed(1)}k";
    }
    return "₱${value.toInt()}";
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, double> grouped = {};

    // Only include PAID/COMPLETED orders
    for (var o in filteredOrders.where((o) {
      final s = o.status.toLowerCase();
      return s == "paid" || s == "completed";
    })) {
      final date = toDate(o.timestamp);
      final key = selectedDay != null
          ? date.hour
          : selectedMonth != null
              ? date.day
              : date.month;
      grouped[key] = (grouped[key] ?? 0) + o.totalAmount;
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (entries.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const SizedBox(
          height: 220,
          child: Center(
            child: Text("No sales data available",
                style: TextStyle(color: Colors.grey)),
          ),
        ),
      );
    }

    // Find the maximum sales value
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Decide interval based on scale
    final interval = maxY <= 5000
        ? 500 // ✅ gives 1k, 1.5k, 2k, etc.
        : maxY <= 20000
            ? 1000
            : 5000;

    // Round maxY up to nearest interval
    final chartMaxY = ((maxY / interval).ceil() * interval).toDouble();

    // Dynamic bar width
    final barWidth = entries.length > 15 ? 12.0 : 20.0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 320,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: chartMaxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                horizontalInterval: interval.toDouble(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 56,
                    getTitlesWidget: (value, meta) {
                      if (value % interval == 0) {
                        return Text(
                          _formatCurrency(value),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // Skip some labels if too dense
                      if (selectedMonth != null &&
                          entries.length > 15 &&
                          value.toInt() % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _labelFor(value.toInt()),
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),

              // Tooltip
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rod.toY <= 0) return null;
                    final xLabel = _labelFor(group.x.toInt());
                    final amount = rod.toY % 1 == 0
                        ? rod.toY.toStringAsFixed(0)
                        : rod.toY.toStringAsFixed(2);
                    return BarTooltipItem(
                      "$xLabel\n₱$amount",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),

              // Bars
              barGroups: entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1976D2), Color(0xFF26C6DA)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: barWidth,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }).toList(),
            ),
            swapAnimationDuration: const Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
        ),
      ),
    );
  }
}
