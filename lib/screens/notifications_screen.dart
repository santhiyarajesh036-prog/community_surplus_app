import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  /// TIME AGO FORMAT
  String timeAgo(Timestamp timestamp) {
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  /// MARK ALL AS READ WHEN SCREEN OPENS
  Future<void> _markAllRead() async {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('toEmail', isEqualTo: userEmail)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in unread.docs) {
      doc.reference.update({'isRead': true});
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_markAllRead);
  }

  @override
  Widget build(BuildContext context) {

    final userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('toEmail', isEqualTo: userEmail)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No notifications'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {

              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final bool isRead = data['isRead'] == true;
              final String? chatId = data['chatId'];
              final Timestamp? createdAt = data['createdAt'];

              return ListTile(
                leading: Icon(
                  isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: isRead ? Colors.grey : Colors.blue,
                ),

                title: Text(
                  data['title'] ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['message'] ?? ''),
                    const SizedBox(height: 4),
                    if (createdAt != null)
                      Text(
                        timeAgo(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),

                tileColor:
                isRead ? Colors.grey.shade100 : Colors.blue.shade50,

                /// 🔥 OPEN CHAT WHEN CLICKED
                onTap: () async {

                  /// mark read
                  await doc.reference.update({'isRead': true});

                  if (!context.mounted) return;

                  /// open chat if exists
                  if (chatId != null && chatId.isNotEmpty) {

                    final chatDoc = await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId)
                        .get();

                    if (!chatDoc.exists) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Chat no longer exists")),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: chatId),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}