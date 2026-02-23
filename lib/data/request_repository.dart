import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/notification_service.dart';

class RequestRepository {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // ➕ ADD NEW REQUEST (Requester side)
  // ─────────────────────────────────────────────
  static Future<void> addRequest({
    required String itemId,
    required String itemName,
    required String requesterEmail,
    required String donorEmail,
  }) async {
    await _db.collection('requests').add({
      'itemId': itemId,
      'itemName': itemName,
      'requesterEmail': requesterEmail,
      'donorEmail': donorEmail,
      'status': 'pending',
      'seen': false, // ✅ REQUIRED
      'createdAt': FieldValue.serverTimestamp(), // ✅ FIXED
    });
  }

  // ─────────────────────────────────────────────
  // 📊 GET REQUESTS FOR ITEM (with queue number)
  // ─────────────────────────────────────────────
  static Stream<List<RequestModel>> getItemRequests(String itemId) {
    return _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .asMap()
          .entries
          .map(
            (e) => RequestModel.fromDoc(
          e.value,
          e.key + 1, // queue number
        ),
      )
          .toList();
    });
  }


  // ─────────────────────────────────────────────
  // ✅ APPROVE REQUEST (Donor side)
  // ─────────────────────────────────────────────
  static Future<String> approveRequest({
    required String requestId,
    required String itemId,
    required String donorEmail,
    required String requesterEmail,
    required String itemName,
  }) async {
    final batch = _db.batch();

    // 1️⃣ Approve selected request
    final approvedRef = _db.collection('requests').doc(requestId);
    batch.update(approvedRef, {
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    });

    // 2️⃣ Reject other pending requests
    final pendingRequests = await _db
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in pendingRequests.docs) {
      if (doc.id != requestId) {
        batch.update(doc.reference, {'status': 'rejected'});
      }
    }

    // 3️⃣ Mark item as claimed
    batch.update(
      _db.collection('items').doc(itemId),
      {'status': 'claimed'},
    );

    // 4️⃣ Create chat
    final chatRef = _db.collection('chats').doc();
    batch.set(chatRef, {
      'participants': [donorEmail, requesterEmail],
      'itemId': itemId,
      'itemName': itemName,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    // 🔥 Commit Firestore batch
    await batch.commit();

    // 5️⃣ CREATE IN-APP NOTIFICATION
    await NotificationService.createNotification(
      userEmail: requesterEmail,
      title: 'Request Approved 🎉',
      message: 'Your request for "$itemName" has been approved.',
      type: 'request_approved',
      chatId: chatRef.id,
    );

    return chatRef.id;
  }
}
