import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// CREATE NEW NOTIFICATION
  static Future<void> createNotification({
    required String userEmail, // receiver
    required String title,
    required String message,
    String type = 'general',
    String? chatId,
  }) async {
    await _db.collection('notifications').add({
      'toEmail': userEmail, // keep database field consistent
      'title': title,
      'message': message,
      'type': type,
      'chatId': chatId ?? '',
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// MARK ALL NOTIFICATIONS AS READ
  static Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('notifications')
        .where('toEmail', isEqualTo: user.email)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }
}
