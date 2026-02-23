import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String name;
  final String category;
  final bool isFree;
  final double price;
  final String donorEmail;
  final String condition;
  final String status;
  final DateTime? expiryAt;
  final String? imagePath; // ✅ LOCAL IMAGE PATH

  ItemModel({
    required this.id,
    required this.name,
    required this.category,
    required this.isFree,
    required this.price,
    required this.donorEmail,
    required this.condition,
    required this.status,
    this.expiryAt,
    this.imagePath, // ✅ ADD THIS
  });

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ItemModel(
      id: doc.id,
      name: data['name'],
      category: data['category'],
      isFree: data['isFree'],
      price: (data['price'] ?? 0).toDouble(),
      donorEmail: data['donorEmail'],
      condition: data['condition'],
      status: data['status'],
      expiryAt: data['expiryAt'] != null
          ? (data['expiryAt'] as Timestamp).toDate()
          : null,
      imagePath: data['imagePath'], // ✅ READ LOCAL PATH
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'isFree': isFree,
      'price': price,
      'donorEmail': donorEmail,
      'condition': condition,
      'status': status,
      'expiryAt': expiryAt,
      'imagePath': imagePath, // ✅ SAVE LOCAL PATH
    };
  }
}
