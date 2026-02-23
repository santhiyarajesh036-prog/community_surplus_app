import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class ItemRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ➕ ADD ITEM (LOCAL IMAGE PATH SUPPORTED)
  static Future<void> addItem(ItemModel item) async {
    await _db.collection('items').add({
      ...item.toMap(), // ✅ IMPORTANT (includes imagePath)
      'createdAt': FieldValue.serverTimestamp(), // ✅ SORTING
    });
  }

  /// ❌ DELETE ITEM
  static Future<void> deleteItem(String itemId) async {
    await _db.collection('items').doc(itemId).delete();
  }

  /// 📥 GET ITEMS
  static Stream<List<ItemModel>> getItems() {
    return _db
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs.map(ItemModel.fromFirestore).toList(),
    );
  }
}
