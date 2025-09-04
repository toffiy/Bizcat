// lib/features/dashboard/models/customer.dart
class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String address;
  final String phone;
  final String photoUrl; // ✅ new field

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.address,
    required this.phone,
    required this.photoUrl, // ✅ include in constructor
  });

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      firstName: (map['firstName'] ?? '').toString(),
      lastName:  (map['lastName']  ?? '').toString(),
      email:     (map['email']     ?? '').toString(),
      address:   (map['address']   ?? '').toString(),
      phone:     (map['phone']     ?? '').toString(),
      photoUrl:  (map['photoUrl']  ?? map['buyerPhotoURL'] ?? '').toString(), 
    );
  }
}
