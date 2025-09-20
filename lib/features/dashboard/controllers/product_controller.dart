import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img; // ✅ For safe dimension reading
import 'package:flutter/foundation.dart';

import '../models/product.dart';

class ProductController {
  final _firestore = FirebaseFirestore.instance;

  // 🔹 Compress image dynamically to stay under targetKB
    Future<XFile> compressImageToJpgUnderKB(XFile file, int targetKB) async {
      final dir = await getTemporaryDirectory();

      // Always start with a unique temp file name
      String targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Skip if already small enough
      final originalSizeKB = await File(file.path).length() / 1024;
      if (originalSizeKB <= targetKB) return file;

      int quality = 95;
      const int minQuality = 10;
      const int minDimension = 512;

      // Convert to JPEG first if needed (different path!)
      if (!file.path.toLowerCase().endsWith('.jpg') &&
          !file.path.toLowerCase().endsWith('.jpeg')) {
        final convertedPath = '${dir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final converted = await FlutterImageCompress.compressAndGetFile(
          file.path,
          convertedPath,
          quality: 95,
          format: CompressFormat.jpeg,
        );
        if (converted == null) throw Exception("Initial format conversion failed.");
        file = XFile(converted.path);
      }

      // Get dimensions
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) throw Exception("Could not decode image.");
      int width = decodedImage.width;
      int height = decodedImage.height;

      XFile? compressedFile;

      do {
        // Always generate a new target path for each iteration
        targetPath = '${dir.path}/compressed_${DateTime.now().microsecondsSinceEpoch}.jpg';

        final result = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          quality: quality,
          format: CompressFormat.jpeg,
          minWidth: width,
          minHeight: height,
        );

        if (result == null) throw Exception("Image compression failed.");
        compressedFile = XFile(result.path);

        final fileSizeKB = await File(compressedFile.path).length() / 1024;
        if (fileSizeKB <= targetKB) break;

        if (quality > minQuality) {
          quality -= 5;
        } else {
          width = (width * 0.9).round();
          height = (height * 0.9).round();
          if (width < minDimension || height < minDimension) break;
        }

        // Update file for next loop iteration
        file = compressedFile;

      } while (true);

      return compressedFile!;
    }


  // ✅ Upload image to Cloudinary (with compression if > targetKB)
  Future<String> uploadImageToCloudinary(XFile imageFile, {int targetKB = 900}) async {
    // Ensure JPG and under targetKB
    imageFile = await compressImageToJpgUnderKB(imageFile, targetKB);

    final cloudName = 'ddpj3pix5';
    final uploadPreset = 'bizcat_unsigned';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);

    if (response.statusCode == 200 && data['secure_url'] != null) {
      return data['secure_url'];
    } else {
      throw Exception(
        "Cloudinary upload failed: ${data['error']?['message'] ?? 'Unknown error'}",
      );
    }
  }

  // ✅ Add product (reject negative price)
  Future<void> addProduct(
    String name,
    int quantity,
    double price,
    String imageUrl,
  ) async {
    if (price < 0) {
      throw Exception('Price cannot be negative.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    // 🔍 Check for duplicate product name (case-insensitive)
    final existing = await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .where('name', isEqualTo: name.trim())
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('A product with this name already exists.');
    }

    final productId = _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc()
        .id;

    final product = Product(
      id: productId,
      name: name.trim(),
      quantity: quantity,
      price: price,
      imageUrl: imageUrl,
    );

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc(productId)
        .set({
      ...product.toMap(),
      'timestamp': FieldValue.serverTimestamp(),
      'sellerId': sellerId,
    });
  }

  // ✅ Check if product exists
  Future<bool> productExists(String name, String sellerId) async {
    final query = await FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .where('productName', isEqualTo: name.trim())
        .get();

    return query.docs.isNotEmpty;
  }

  // ✅ Stream products for current seller
  Stream<QuerySnapshot> getProductsStream() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield* const Stream.empty();
      return;
    }

    final sellerId = user.uid;

    yield* _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ Stream products by sellerId
  Stream<List<Product>> getProducts(String sellerId) async* {
    yield* _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ✅ Update product (reject negative price if provided)
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
    if (updatedData.containsKey('price') &&
        (updatedData['price'] as num) < 0) {
      throw Exception('Price cannot be negative.');
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc(productId)
        .update(updatedData);
  }

  // ✅ Deduct stock safely
  Future<bool> deductProductStock(String productId, int orderedQty) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final sellerId = user.uid;
    final productRef = _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc(productId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productRef);

        if (!snapshot.exists) throw Exception("Product not found");

        final currentQty = snapshot['quantity'] as int;
        final newQty = currentQty - orderedQty;

        if (newQty < 0) throw Exception("Not enough stock available");

        transaction.update(productRef, {'quantity': newQty});
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ✅ Stream trash
  Stream<QuerySnapshot> getTrashStream() async* {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield* const Stream.empty();
      return;
    }

    final sellerId = user.uid;

    yield* _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('trash')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ Move product to trash
  Future<void> moveToTrash(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('trash')
        .doc(productId)
        .set({
      ...productData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc(productId)
        .delete();
  }

  // ✅ Restore product from trash
  Future<void> restoreProduct(
    String productId,
    Map<String, dynamic> productData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .doc(productId)
        .set({
      ...productData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('trash')
        .doc(productId)
        .delete();
  }

  // ✅ Delete permanently from trash
  Future<void> deleteFromTrash(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('trash')
        .doc(productId)
        .delete();
  }

  // 📊 =========================
  // SALES ANALYTICS METHODS
  // ==========================

  // ✅ Get top-selling products (by quantity sold)
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    int limit = 5,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final sellerId = user.uid;

    // Step 1: Fetch all products for this seller (to get imageUrl & name)
    final productsSnapshot = await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .get();

    // Map productId -> { name, imageUrl }
    final Map<String, Map<String, dynamic>> productInfo = {
      for (var doc in productsSnapshot.docs)
        doc.id: {
          'productName': doc.data()['name'] ?? '',
          'imageUrl': doc.data()['imageUrl'] ?? '',
        }
    };

    // Step 2: Fetch all orders for this seller
    final ordersSnapshot = await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('orders')
        .get();

    // Step 3: Aggregate sales
    final Map<String, Map<String, dynamic>> productSales = {};

    for (var orderDoc in ordersSnapshot.docs) {
      final orderData = orderDoc.data();

      // If order contains multiple items
      if (orderData['items'] != null && orderData['items'] is List) {
        final items = List<Map<String, dynamic>>.from(orderData['items']);
        for (var item in items) {
          final productId = item['productId'];
          final qty = (item['quantity'] ?? 0) as int;
          final price = (item['price'] ?? 0.0) as num;

          if (!productSales.containsKey(productId)) {
            productSales[productId] = {
              'productId': productId,
              'productName': productInfo[productId]?['productName'] ?? '',
              'imageUrl': productInfo[productId]?['imageUrl'] ?? '',
              'totalQty': 0,
              'totalRevenue': 0.0,
            };
          }

          productSales[productId]!['totalQty'] += qty;
          productSales[productId]!['totalRevenue'] += qty * price;
        }
      }
      // If order is a single product
      else {
        final productId = orderData['productId'];
        final qty = (orderData['quantity'] ?? 0) as int;
        final price = (orderData['price'] ?? 0.0) as num;

        if (!productSales.containsKey(productId)) {
          productSales[productId] = {
            'productId': productId,
            'productName': productInfo[productId]?['productName'] ?? '',
            'imageUrl': productInfo[productId]?['imageUrl'] ?? '',
            'totalQty': 0,
            'totalRevenue': 0.0,
          };
        }

        productSales[productId]!['totalQty'] += qty;
        productSales[productId]!['totalRevenue'] += qty * price;
      }
    }

    // Step 4: Sort by quantity sold
    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['totalQty'] as int).compareTo(a['totalQty'] as int));

    // Step 5: Return top N
    return sorted.take(limit).toList();
  }

  // ✅ Get full sales breakdown per product
  Future<List<Map<String, dynamic>>> getSalesBreakdown() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final sellerId = user.uid;

    final salesSnapshot = await _firestore
        .collection('sales') // or 'orders'
        .where('sellerId', isEqualTo: sellerId)
        .get();

    final Map<String, Map<String, dynamic>> breakdown = {};

    for (var doc in salesSnapshot.docs) {
      final data = doc.data();
      final productId = data['productId'];
      final productName = data['productName'];
      final qty = (data['quantity'] ?? 0) as int;
      final price = (data['price'] ?? 0.0) as num;

      if (!breakdown.containsKey(productId)) {
        breakdown[productId] = {
          'productId': productId,
          'productName': productName,
          'totalQty': 0,
          'totalRevenue': 0.0,
        };
      }

      breakdown[productId]!['totalQty'] += qty;
      breakdown[productId]!['totalRevenue'] += qty * price;
    }

    // Sort by revenue (descending)
    final sorted = breakdown.values.toList()
      ..sort((a, b) =>
          (b['totalRevenue'] as num).compareTo(a['totalRevenue'] as num));

    return sorted;
  }
}
