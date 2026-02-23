import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';
import '../models/request_model.dart';
import '../data/request_repository.dart';
import '../services/request_service.dart';

class DonorRequestsScreen extends StatelessWidget {
  final String itemId;

  const DonorRequestsScreen({
    super.key,
    required this.itemId,
  });

  /// ✅ MARK REQUEST AS SEEN (SAFE)
  Future<void> _markAsSeen(String requestId) async {
    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({'seen': true});
  }

  @override
  Widget build(BuildContext context) {
    final donorEmail = FirebaseAuth.instance.currentUser?.email;

    if (donorEmail == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Item Requests'),
      ),
      body: StreamBuilder<List<RequestModel>>(
        stream: RequestRepository.getItemRequests(itemId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!;

          if (requests.isEmpty) {
            return const Center(child: Text('No requests received'));
          }

          final isClaimed =
          requests.any((r) => r.status == 'accepted');

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: ListTile(
                  onTap: () async {
                    /// ✅ Mark as seen ONLY ON TAP
                    if (!request.seen) {
                      await _markAsSeen(request.id);
                    }
                  },
                  leading: CircleAvatar(
                    backgroundColor:
                    request.seen ? Colors.grey : Colors.blue,
                    child: Text(
                      '#${request.queueNumber}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    request.itemName,
                    style: TextStyle(
                      fontWeight: request.seen
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Requester: ${request.requesterEmail}'),
                      const SizedBox(height: 4),
                      _statusChip(request.status),
                    ],
                  ),
                  trailing: request.status == 'pending' && !isClaimed
                      ? ElevatedButton(
                    onPressed: () async {

                      final chatId = await RequestService.acceptRequest(
                        requestId: request.id,
                        itemId: request.itemId,
                        itemName: request.itemName,
                        donorEmail: donorEmail,
                        requesterEmail: request.requesterEmail,
                      );

                      if (!context.mounted) return;

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chatId),
                        ),
                      );
                    },
                    child: const Text('Approve'),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 🏷 STATUS CHIP
  Widget _statusChip(String status) {
    final color = status == 'accepted'
        ? Colors.green
        : status == 'rejected'
        ? Colors.red
        : Colors.orange;
    return Chip(
      label: Text(status.toUpperCase()),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
