import 'package:flutter/material.dart';

class TopSellingTile extends StatelessWidget {
  final int rank;
  final String name;
  final int sold;
  final double revenue;
  final String? imageUrl;

  const TopSellingTile({
    super.key,
    required this.rank,
    required this.name,
    required this.sold,
    required this.revenue,
    this.imageUrl,
  });

  Color _rankColor() {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade400;
    if (rank == 3) return Colors.brown.shade400;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    // Only show top 3
    if (rank > 3) return const SizedBox.shrink();

    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor(),
              boxShadow: [
                BoxShadow(
                  color: _rankColor().withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Product image with border
          CircleAvatar(
            radius: 34,
            backgroundColor: _rankColor().withOpacity(0.2),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!)
                : null,
            child: (imageUrl == null || imageUrl!.isEmpty)
                ? const Icon(Icons.image_not_supported,
                    size: 28, color: Colors.grey)
                : null,
          ),

          const SizedBox(height: 10),

          // Product name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 6),

          // Stats
          Text(
            "Sold: $sold",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            "₱${revenue.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
