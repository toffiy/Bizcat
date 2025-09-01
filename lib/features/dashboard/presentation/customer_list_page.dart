import 'package:flutter/material.dart';
import '../controllers/customer_controller.dart';
import '../widgets/customer_design.dart';
import '../models/customer.dart';

class CustomerListPage extends StatelessWidget {
  const CustomerListPage({super.key});

  String _initials(Customer c) {
    final f = c.firstName.isNotEmpty ? c.firstName[0] : '';
    final l = c.lastName.isNotEmpty ? c.lastName[0] : '';
    return (f + l).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CustomerController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Customer History'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CustomerWithStats>>(
        stream: controller.getCustomersWithOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No buyers with orders yet'));
          }

          final customers = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: customers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cws = customers[index];
              return CustomerInfoCard(
                customer: cws.customer,
                initials: _initials(cws.customer),
                ordersCount: cws.ordersCount,
                totalSpent: cws.totalSpent,
                lastOrderDate: cws.lastOrderDate,
              );
            },
          );
        },
      ),
    );
  }
}
