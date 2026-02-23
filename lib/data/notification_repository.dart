import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Mark all notifications as read for current user
  static Future<void> markAllAsRead() async {

    final email = FirebaseAuth.instance.currentUser!.email!;

    final query = await _db
        .collection('notifications')
        .where('toEmail', isEqualTo: email)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (var doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}