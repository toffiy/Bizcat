import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/product_controller.dart';
import '../models/product.dart';

class LiveControlPage extends StatefulWidget {
  const LiveControlPage({super.key});

  @override
  State<LiveControlPage> createState() => _LiveControlPageState();
}

class _LiveControlPageState extends State<LiveControlPage> with WidgetsBindingObserver {
  final productController = ProductController();
  String get userId => FirebaseAuth.instance.currentUser!.uid;

  String searchQuery = "";
  final TextEditingController _liveLinkController = TextEditingController();
  bool _isLive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadProfileLiveData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveLinkController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // 🔑 Detect background/exit and auto-end live
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isLive) {
        await _endLiveAndHideAll();
      }
    }
  }

  Future<void> _loadProfileLiveData() async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(userId).get();
    if (!mounted) return;
    if (doc.exists) {
      final data = doc.data()!;
      _liveLinkController.text = data['fbLiveLink'] ?? '';
      _isLive = data['isLive'] ?? false;
      setState(() {});
    }
  }

  bool isValidLiveUrl(String url) {
    final pattern = RegExp(
      r'^https?:\/\/(www\.)?('
      r'facebook\.com\/.*(live|share|watch\/live).*' // Facebook
      r'|tiktok\.com\/(@[A-Za-z0-9._-]+\/live|live\/.*)' // TikTok full live
      r'|vt\.tiktok\.com\/[A-Za-z0-9]+\/?' // TikTok short links
      r')',
      caseSensitive: false,
    );
    return pattern.hasMatch(url.trim());
  }

  Future<void> _goLive() async {
    final link = _liveLinkController.text.trim();

    if (link.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste your Live link')),
      );
      return;
    }

    if (!isValidLiveUrl(link)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Live URL format')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await FirebaseFirestore.instance.collection('sellers').doc(userId).update({
      'fbLiveLink': link,
      'isLive': true,
    });

    if (!mounted) return;
    setState(() {
      _isLive = true;
      _isLoading = false;
    });
  }

  Future<void> _endLiveAndHideAll() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(userId)
          .collection('products')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var productDoc in productsSnapshot.docs) {
        batch.update(productDoc.reference, {'isVisible': false});
      }

      final sellerRef = FirebaseFirestore.instance.collection('sellers').doc(userId);
      batch.update(sellerRef, {
        'isLive': false,
        'fbLiveLink': FieldValue.delete(),
      });

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _isLive = false;
        _liveLinkController.clear();
      });

      debugPrint("✅ Live ended, all products hidden, and UI reset.");
    } catch (e) {
      debugPrint("❌ Error ending live: $e");
    }
  }

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
        title: const Text("Live Product Control", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 🔗 Live Link + Go Live / End Live Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                    controller: _liveLinkController,
                    decoration: InputDecoration(
                      labelText: 'Live Link',
                      hintText: 'https://facebook.com/yourpage/live',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!_isLive && !_isLoading) ? _goLive : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Go Live Now'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLive ? _endLiveAndHideAll : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('End Live'),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
              ],
            ),
          ),

          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search product...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
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
                  return const Center(child: Text("No products found", style: TextStyle(fontSize: 16, color: Colors.grey)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final p = filteredProducts[index];
                    final isVisible = p.isVisible;
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
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: 160,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(height: 8),

                          // Name & Price
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
                                  color: inStock ? Colors.green : Colors.redAccent,
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

                          // Show / Hide Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (_isLive && !isVisible && inStock)
                                        ? Colors.blue
                                        : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: (_isLive && !isVisible && inStock) ? 6 : 0,
                                  ),
                                  onPressed: (_isLive && !isVisible && inStock)
                                      ? () => _showNow(p)
                                      : null,
                                  child: const Text("Show"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isVisible ? Colors.red : Colors.grey.shade400,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    elevation: isVisible ? 6 : 0,
                                  ),
                                  onPressed: isVisible ? () => _hide(p) : null,
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
