import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/request_repository.dart';

class RequestService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // --------------------------------------------------
  // CHECK IF USER ALREADY REQUESTED
  // --------------------------------------------------
  static Future<bool> hasRequested({
    required String itemId,
    required String requesterEmail,
  }) async {
    final snapshot = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('requesterEmail', isEqualTo: requesterEmail)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // --------------------------------------------------
  // GET REQUEST STATUS
  // --------------------------------------------------
  static Future<String?> getRequestStatus({
    required String itemId,
    required String requesterEmail,
  }) async {
    final snapshot = await _firestore
        .collection('requests')
        .where('itemId', isEqualTo: itemId)
        .where('requesterEmail', isEqualTo: requesterEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return snapshot.docs.first['status'] as String?;
  }

  // --------------------------------------------------
  // CREATE REQUEST
  // --------------------------------------------------
  static Future<void> requestItem({
    required String itemId,
    required String itemName,
    required String donorEmail,
    required String requesterEmail,
  }) async {
    if (donorEmail == requesterEmail) {
      throw Exception("You cannot request your own item");
    }

    final alreadyRequested = await hasRequested(
      itemId: itemId,
      requesterEmail: requesterEmail,
    );

    if (alreadyRequested) {
      throw Exception("You already requested this item");
    }

    await RequestRepository.addRequest(
      itemId: itemId,
      itemName: itemName,
      requesterEmail: requesterEmail,
      donorEmail: donorEmail,
    );
  }

  // --------------------------------------------------
  // ACCEPT REQUEST  🔥 FINAL WORKING VERSION
  // --------------------------------------------------
  static Future<String> acceptRequest({
    required String requestId,
    required String itemId,
    required String itemName,
    required String requesterEmail,
    required String donorEmail,
  }) async {

    /// 1️⃣ Update request status
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    /// 2️⃣ Mark item as claimed
    await _firestore.collection('items').doc(itemId).update({
      'status': 'claimed',
    });

    /// 3️⃣ Create chat document (AUTO ID)
    final chatRef = await _firestore.collection('chats').add({
      'participants': [requesterEmail, donorEmail],
      'itemId': itemId,
      'itemName': itemName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Chat started',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    final chatId = chatRef.id;

    /// 4️⃣ Insert FIRST MESSAGE inside subcollection
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': 'Request approved! You can now chat about "$itemName".',
      'senderEmail': donorEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'system',
    });

    /// 5️⃣ Update chat last message again (safe sync)
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage':
      'Request approved! You can now chat about "$itemName".',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    /// 6️⃣ Send notification WITH chatId
    await _firestore.collection('notifications').add({
      'toEmail': requesterEmail,
      'fromEmail': donorEmail,
      'title': 'Request Approved 🎉',
      'message': '$donorEmail approved your request for $itemName',
      'type': 'request_approved',
      'itemId': itemId,
      'chatId': chatId,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    return chatId;
  }

  // --------------------------------------------------
  // REJECT REQUEST
  // --------------------------------------------------
  static Future<void> rejectRequest({
    required String requestId,
  }) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': 'rejected',
    });
  }
}