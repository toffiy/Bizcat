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
    setState(() {
      topSelling = data;
      loadingHighlights = false;
    });
  }

  // ✅ Show Add Product Dialog
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

  // ✅ Show Edit Product Dialog
  void _showEditProductDialog(String id, Map<String, dynamic> data) {
    EditProductDialog.show(
      context,
      name: data['name'],
      qty: data['quantity'],
      price: (data['price'] as num).toDouble(),
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

  // ✅ Confirmation before moving to Trash
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Product moved to Trash"),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
              );
            },
            icon: const Icon(Icons.delete_outline),
            tooltip: "Go to Trash",
          ),
        ],
      ),
      body: Column(
        children: [
          // 📊 Highlights Section
          if (loadingHighlights)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (topSelling.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      SizedBox(width: 6),
                      Text(
                        "Top Selling Products",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                SizedBox(
                  height: 210,
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

          // 📦 Product List
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
