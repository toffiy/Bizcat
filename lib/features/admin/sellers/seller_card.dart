import 'package:flutter/material.dart';

class SellerCard extends StatelessWidget {
  final String id;
  final String name;
  final String email;
  final String status;
  final String profileUrl;
  final VoidCallback onTap;

  const SellerCard({
    super.key,
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.profileUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: profileUrl.isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(profileUrl))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(email),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: status == 'suspended' ? Colors.red : Colors.green,
        ),
        onTap: onTap,
      ),
    );
  }
}
