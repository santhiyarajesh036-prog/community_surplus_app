import 'package:cloud_firestore/cloud_firestore.dart';

class RequestModel {
  final String id;
  final String itemId;
  final String itemName;
  final String requesterEmail;
  final String donorEmail;
  final String status;
  final bool seen;
  final int queueNumber;
  final Timestamp createdAt;

  RequestModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.requesterEmail,
    required this.donorEmail,
    required this.status,
    required this.seen,
    required this.queueNumber,
    required this.createdAt,
  });

  /// ✅ SAFE factory constructor
  factory RequestModel.fromDoc(
      QueryDocumentSnapshot doc,
      int queueNumber,
      ) {
    final data = doc.data() as Map<String, dynamic>;

    return RequestModel(
      id: doc.id,
      itemId: data['itemId'],
      itemName: data['itemName'],
      requesterEmail: data['requesterEmail'],
      donorEmail: data['donorEmail'],
      status: data['status'],
      seen: data['seen'] ?? false, // ✅ IMPORTANT
      queueNumber: queueNumber,
      createdAt: data['createdAt'],
    );
  }
}
