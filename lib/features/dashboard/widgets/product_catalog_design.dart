import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final String? sku;
  final String? description;
  final int quantity;
  final double price;
  final String? category;
  final String? imageUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.name,
    this.sku,
    this.description,
    required this.quantity,
    required this.price,
    this.category,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Square image with badge overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 1, // Makes it square
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 40),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusText(),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (sku != null && sku!.isNotEmpty)
                  Text("SKU: $sku", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                if (description != null && description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      description!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Text("₱${price.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                const SizedBox(height: 4),
                Text("Quantity: $quantity", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                if (category != null && category!.isNotEmpty)
                  Text("Category: $category", style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: const Text("Edit", style: TextStyle(color: Colors.blue)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
