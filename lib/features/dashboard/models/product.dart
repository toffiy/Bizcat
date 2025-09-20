class Product {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl; // ✅ New field
  final bool isVisible;
  int totalQuantity; // 📊 For sales stats
  double totalSales;  // 📊 For sales stats

  Product({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl = '',
    this.isVisible = false,
    this.totalQuantity = 0, // default to 0
    this.totalSales = 0.0,  // default to 0.0
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'isVisible': isVisible,
      'totalQuantity': totalQuantity,
      'totalSales': totalSales,
    };
  }

  factory Product.fromMap(String id, Map<String, dynamic> map) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] is int)
          ? (map['price'] as int).toDouble()
          : (map['price'] is double)
              ? map['price']
              : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      isVisible: map['isVisible'] ?? false,
      totalQuantity: map['totalQuantity'] ?? 0,
      totalSales: (map['totalSales'] is int)
          ? (map['totalSales'] as int).toDouble()
          : (map['totalSales'] is double)
              ? map['totalSales']
              : double.tryParse(map['totalSales']?.toString() ?? '0') ?? 0.0,
    );
  }
}
