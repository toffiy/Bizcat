import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../controllers/product_controller.dart';
import 'trash_page.dart';

// Widgets
import '../widgets/product_card.dart';
import '../widgets/top_selling_card.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/edit_product_dialog.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final ProductController _controller = ProductController();

  List<Map<String, dynamic>> topSelling = [];
  bool loadingHighlights = true;
  bool _addingProduct = false;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() => loadingHighlights = true);
    final data = await _controller.getTopSellingProducts(limit: 5);

    final filtered = data
        .where((p) => p['productName'] != null && p['productName'] != '')
        .toList();

    setState(() {
      topSelling = filtered;
      loadingHighlights = false;
    });
  }

  Future<void> _showAddProductDialog() async {
    if (_addingProduct) return;
    setState(() => _addingProduct = true);

    await AddProductDialog.show(context, (name, qty, price, image) async {
      final imageUrl = await _controller.uploadImageToCloudinary(image);
      await _controller.addProduct(name, qty, price, imageUrl);
      _loadHighlights();
    });

    if (mounted) setState(() => _addingProduct = false);
  }

  void _showEditProductDialog(String id, Map<String, dynamic> data) {
    EditProductDialog.show(
      context,
      name: data['name'],
      qty: data['quantity'] as int,
      price: (data['price'] as num).toInt(),
      onSubmit: (name, qty, price) async {
        await _controller.updateProduct(id, {
          'name': name,
          'quantity': qty,
          'price': price,
        });
        _loadHighlights();
      },
    );
  }

  Future<void> _confirmDelete(String id, Map<String, dynamic> data) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Move to Trash"),
        content: const Text(
          "Are you sure you want to move this product to Trash?\n\n"
          "You can restore it later from the Trash page.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Move to Trash"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _controller.moveToTrash(id, data);
      await _loadHighlights();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product moved to Trash"),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _sectionHeader(String title, {IconData? icon, Color? accent}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 18, color: accent ?? Colors.grey),
          if (icon != null) const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _accentLine({Color? color}) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      height: 2,
      width: 40,
      decoration: BoxDecoration(
        color: color ?? Colors.blueGrey,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Catalog"),
        actions: [
          IconButton(
            onPressed: _addingProduct ? null : _showAddProductDialog,
            icon: const Icon(Icons.add),
            tooltip: "Add Product",
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TrashPage()),
              ).then((_) => _loadHighlights());
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: "Go to Trash",
          ),
        ],
      ),
      body: Column(
        children: [
          // 📊 Top Selling Section
          if (loadingHighlights)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (topSelling.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader("Top Selling Products",
                    icon: Icons.emoji_events, accent: Colors.amber),
                _accentLine(color: Colors.amber.shade400),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: topSelling.length,
                    itemBuilder: (context, index) {
                      final product = topSelling[index];
                      return TopSellingTile(
                        rank: index + 1,
                        name: product['productName'] ?? '',
                        sold: product['totalQty'] ?? 0,
                        revenue: (product['totalRevenue'] as num).toDouble(),
                        imageUrl: product['imageUrl'],
                      );
                    },
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No sales data yet"),
            ),

          // 📦 Product Catalog Section
          _sectionHeader("Product Catalog",
              icon: Icons.inventory_2, accent: Colors.blueGrey),
          _accentLine(color: Colors.blueGrey),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _controller.getProductsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!.docs;

                if (products.isEmpty) {
                  return const Center(child: Text("No products yet"));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return ProductCard(
                      name: data['name'],
                      quantity: data['quantity'],
                      price: (data['price'] as num).toDouble(),
                      imageUrl: data['imageUrl'],
                      onEdit: () => _showEditProductDialog(doc.id, data),
                      onDelete: () => _confirmDelete(doc.id, data),
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
