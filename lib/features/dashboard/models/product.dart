class Product {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl; // ✅ New field
  final bool isVisible;

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl = '', // default empty string
    this.isVisible = false, // default false
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl, // ✅ Include in map
      'isVisible': isVisible,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] ?? 0.0),
      imageUrl: map['imageUrl'] ?? '',
      isVisible: map['isVisible'] ?? false,
    );
  }
}
