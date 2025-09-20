import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/product_controller.dart';
import 'trash_page.dart';
import '../widgets/product_catalog_design.dart'; 

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  final ProductController _controller = ProductController();
  XFile? selectedImage;
  bool isUploading = false;

  // 📊 Highlights state
  List<Map<String, dynamic>> topSelling = [];
  bool loadingHighlights = true;

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

  // ✅ Dialog to Add Product
  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Product"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✅ Image preview
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            setDialogState(() => selectedImage = image);
                            setState(() => selectedImage = image);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[200],
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.image,
                                          size: 40, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text(
                                        "Tap to select image",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: "Name"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Name is required";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Quantity"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Quantity is required";
                          }
                          if (int.tryParse(value) == null) {
                            return "Enter a valid number";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: "Price"),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Price is required";
                          }
                          if (double.tryParse(value) == null) {
                            return "Enter a valid price";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => selectedImage = null);
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final name = nameController.text.trim();
                          final qty = int.parse(qtyController.text);
                          final price = double.parse(priceController.text);

                          if (selectedImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Please select an image")),
                            );
                            return;
                          }

                          // ✅ Prevent double tap
                          setDialogState(() => isUploading = true);
                          setState(() => isUploading = true);

                          try {
                            final imageUrl = await _controller
                                .uploadImageToCloudinary(selectedImage!);

                            await _controller.addProduct(
                                name, qty, price, imageUrl);

                            setState(() {
                              selectedImage = null;
                              isUploading = false;
                            });

                            Navigator.pop(context);
                          } catch (e) {
                            setState(() => isUploading = false);
                            setDialogState(() => isUploading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Upload failed: $e")),
                            );
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Add"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ✅ Dialog to Edit Product
  void _showEditProductDialog(String id, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data['name']);
    final qtyController =
        TextEditingController(text: data['quantity'].toString());
    final priceController =
        TextEditingController(text: data['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0.0;

              if (name.isNotEmpty) {
                _controller.updateProduct(id, {
                  'name': name,
                  'quantity': qty,
                  'price': price,
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
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
            onPressed: _showAddProductDialog,
            icon: const Icon(Icons.add),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Top Selling Products",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: topSelling.length,
                itemBuilder: (context, index) {
                  final product = topSelling[index];
                  return Container(
                    width: 200,
                    margin: EdgeInsets.only(
                      left: index == 0 ? 16 : 8,
                      right: index == topSelling.length - 1 ? 16 : 8,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rank badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? Colors.amber
                                    : index == 1
                                        ? Colors.grey
                                        : Colors.brown,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "#${index + 1}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Product name
                            Text(
                              product['productName'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),

                            // Quantity sold
                            Text(
                              "Sold: ${product['totalQty']}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),

                            // Revenue
                            Text(
                              "₱${product['totalRevenue'].toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            const Spacer(),

                            // Optional: product image placeholder
                            Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: product['imageUrl'] != null &&
                                        product['imageUrl'].toString().isNotEmpty
                                    ? NetworkImage(product['imageUrl'])
                                    : null,
                                child: (product['imageUrl'] == null ||
                                        product['imageUrl'].toString().isEmpty)
                                    ? const Icon(Icons.image_not_supported,
                                        size: 18, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                      price: data['price'],
                      imageUrl: data['imageUrl'],
                      onEdit: () => _showEditProductDialog(doc.id, data),
                      onDelete: () => _controller.moveToTrash(doc.id, data),
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
