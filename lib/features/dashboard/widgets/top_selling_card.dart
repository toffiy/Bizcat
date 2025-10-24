import 'package:flutter/material.dart';

class TopSellingTile extends StatelessWidget {
  final int rank;
  final String? name;
  final int? sold;
  final double? revenue;
  final String? imageUrl;

  const TopSellingTile({
    super.key,
    required this.rank,
    this.name,
    this.sold,
    this.revenue,
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
    if (rank > 3) return const SizedBox.shrink();

    final isDeleted = name == null || name!.isEmpty;

    return Container(
      width: 150, // 👈 narrower card
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Rank badge
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _rankColor(),
              boxShadow: [
                BoxShadow(
                  color: _rankColor().withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              "$rank",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13, // smaller
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Product image or placeholder
          CircleAvatar(
            radius: 26, // 👈 smaller avatar
            backgroundColor: _rankColor().withOpacity(0.15),
            backgroundImage: (!isDeleted && imageUrl != null && imageUrl!.isNotEmpty)
                ? NetworkImage(imageUrl!)
                : null,
            child: (isDeleted || imageUrl == null || imageUrl!.isEmpty)
                ? const Icon(Icons.remove_circle_outline,
                    size: 22, color: Colors.grey)
                : null,
          ),

          const SizedBox(height: 8),

          // Product name or placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              isDeleted ? "—" : name!,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13, // 👈 smaller font
                color: isDeleted ? Colors.grey : Colors.black,
              ),
              maxLines: 2, // 👈 allow 2 lines
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 4),

          // Stats
          if (!isDeleted) ...[
            Text(
              "Sold: $sold",
              style: TextStyle(
                fontSize: 11, // 👈 smaller
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              "₱${revenue?.toStringAsFixed(2) ?? '0.00'}",
              style: const TextStyle(
                fontSize: 13, // 👈 smaller
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ] else
            const Text(
              "No Data",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
