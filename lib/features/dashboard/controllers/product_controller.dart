import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';

class ProductController {
  final _firestore = FirebaseFirestore.instance;

  // ✅ Upload image to Cloudinary
  Future<String> uploadImageToCloudinary(XFile imageFile) async {
    final cloudName = 'ddpj3pix5';
    final uploadPreset = 'bizcat_unsigned';
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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

  Future<void> addProduct(
    String name,
    int quantity,
    double price,
    String imageUrl,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sellerId = user.uid;

    // 🔍 Step 1: Check for duplicate product name (case-insensitive)
    final existing = await _firestore
        .collection('sellers')
        .doc(sellerId)
        .collection('products')
        .where('name', isEqualTo: name.trim())
        .get();

    if (existing.docs.isNotEmpty) {
      // 🚫 Duplicate found — stop here
      throw Exception('A product with this name already exists.');
      // Or show a dialog/snackbar in your UI instead of throwing
    }

    // ✅ Step 2: Safe to create new product
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

  // ✅ Update product
  Future<void> updateProduct(
    String productId,
    Map<String, dynamic> updatedData,
  ) async {
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
}
