import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/product_controller.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final ProductController _controller = ProductController();

  Future<void> _confirmDelete(String productId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to permanently delete this product? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _controller.deleteFromTrash(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Product permanently deleted")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trash Bin")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _controller.getTrashStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Trash is empty"));
          }

          final trashItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: trashItems.length,
            itemBuilder: (context, index) {
              final doc = trashItems[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? 'No Name'),
                  subtitle: Text("Qty: ${data['quantity']} | ₱${data['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.restore, color: Colors.green),
                        onPressed: () async {
                          await _controller.restoreProduct(doc.id, data);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _confirmDelete(doc.id), // ✅ with confirmation
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
