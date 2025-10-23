import 'package:flutter/material.dart';
import '../controllers/customer_controller.dart';
import '../widgets/customer_design.dart';
import '../models/customer.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final controller = CustomerController();
  String searchQuery = '';

  String _initials(Customer c) {
    final f = c.firstName.isNotEmpty ? c.firstName[0] : '';
    final l = c.lastName.isNotEmpty ? c.lastName[0] : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Customer History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 🔎 Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.black12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔹 Customer list
          Expanded(
            child: StreamBuilder<List<CustomerWithStats>>(
              stream: controller.getCustomersWithOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No buyers with orders yet'));
                }

                final customers = snapshot.data!;

                // ✅ Apply search filter
                final filtered = customers.where((cws) {
                  final c = cws.customer;
                  final fullName =
                      '${c.firstName} ${c.lastName}'.toLowerCase();
                  return fullName.contains(searchQuery) ||
                      c.email.toLowerCase().contains(searchQuery) ||
                      c.phone.toLowerCase().contains(searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching customers'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cws = filtered[index];
                    final customer = cws.customer;

                    return CustomerInfoCard(
                      customer: customer,
                      initials: _initials(customer),
                      ordersCount: cws.ordersCount,
                      totalSpent: cws.totalSpent,
                      lastOrderDate: cws.lastOrderDate,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
