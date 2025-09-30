import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.onEdit,
    required this.onDelete,
  });

  Color _statusColor() {
    if (quantity > 5) return Colors.green;
    if (quantity > 0) return Colors.orange;
    return Colors.red;
  }

  String _statusText() {
    if (quantity > 5) return "In Stock";
    if (quantity > 0) return "Low Stock";
    return "Out of Stock";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with stock badge
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported,
                            size: 48, color: Colors.grey),
                      ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusText(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("₱${price.toStringAsFixed(2)}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.green[700])),
                const SizedBox(height: 6),
                Text("Qty: $quantity",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700])),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue)),
              IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red)),
            ],
          )
        ],
      ),
    );
  }
}
