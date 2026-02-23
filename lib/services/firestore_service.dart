import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add donated item
  static Future<void> addItem(ItemModel item) async {
    await _db.collection('items').add({
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'isFree': item.isFree,
      'price': item.price,
      'donorEmail': item.donorEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all items (real-time)
  static Stream<List<ItemModel>> getItems() {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ItemModel(
          id: doc.id,
          name: data['name'],
          category: data['category'],
          isFree: data['isFree'],
          price: (data['price'] as num).toDouble(),
          donorEmail: data['donorEmail'],
        );
      }).toList();
    });
  }
}
