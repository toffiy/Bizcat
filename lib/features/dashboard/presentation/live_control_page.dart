import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/product_controller.dart';
import '../models/product.dart';

class LiveControlPage extends StatefulWidget {
  const LiveControlPage({super.key});

  @override
  State<LiveControlPage> createState() => _LiveControlPageState();
}

class _LiveControlPageState extends State<LiveControlPage> {
  final productController = ProductController();
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  String searchQuery = "";

  Future<void> _showNow(Product product) async {
    await productController.updateProduct(product.id, {'isVisible': true});
    setState(() {});
  }

  Future<void> _hide(Product product) async {
    await productController.updateProduct(product.id, {'isVisible': false});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Live Product Control",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search product...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),

          // 📦 Product List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: productController.getProducts(userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final products = snapshot.data!;
                final filteredProducts = products.where((p) {
                  return p.name.toLowerCase().contains(searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                    child: Text(
                      "No products found",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    final isLive = p.isVisible;
                    final inStock = (p.quantity) > 0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(
                                    p.imageUrl,
                                    width: double.infinity,
                                    height: 160,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.broken_image, size: 40),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 160,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 8),

                          // Name & Price
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₱${p.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Stock & Qty
                          Row(
                            children: [
                              Text(
                                inStock ? "in stock" : "out of stock",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: inStock
                                      ? Colors.green
                                      : Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Qty: ${p.quantity}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Buttons under image
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (!isLive && inStock)
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    shadowColor: (!isLive && inStock)
                                        ? Colors.blueAccent
                                        : Colors.transparent,
                                    elevation: (!isLive && inStock) ? 6 : 0,
                                  ),
                                  onPressed: (!isLive && inStock)
                                      ? () => _showNow(p)
                                      : null,
                                  child: const Text("Show"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isLive
                                        ? Colors.red
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    shadowColor: isLive
                                        ? Colors.redAccent
                                        : Colors.transparent,
                                    elevation: isLive ? 6 : 0,
                                  ),
                                  onPressed: isLive ? () => _hide(p) : null,
                                  child: const Text("Hide"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
