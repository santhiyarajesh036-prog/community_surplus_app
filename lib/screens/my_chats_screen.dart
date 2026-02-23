import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MyChatsScreen extends StatelessWidget {
  const MyChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user.email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final doc = chats[index];
              final data = doc.data() as Map<String, dynamic>;

              final participants = List<String>.from(data['participants']);
              final otherUser =
              participants.firstWhere((e) => e != user.email);

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: doc.id),
                    ),
                  );
                },
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [

                      /// 🧑 AVATAR + 🟢 ONLINE STATUS
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .where('email', isEqualTo: otherUser)
                            .limit(1)
                            .snapshots(),
                        builder: (context, userSnap) {
                          bool isOnline = false;

                          if (userSnap.hasData &&
                              userSnap.data!.docs.isNotEmpty) {
                            final userData = userSnap.data!.docs.first.data()
                            as Map<String, dynamic>;
                            isOnline = userData['isOnline'] == true;
                          }

                          return Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.green.shade300,
                                child: Text(
                                  otherUser[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              /// 🟢 ONLINE DOT
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(width: 12),

                      /// 💬 Chat Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['itemName'] ?? 'Chat',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),

                            /// 🔴 Unread-aware last message
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(doc.id)
                                  .collection('messages')
                                  .where('isRead', isEqualTo: false)
                                  .where('senderEmail',
                                  isNotEqualTo: user.email)
                                  .snapshots(),
                              builder: (context, snap) {
                                final unread =
                                    snap.data?.docs.length ?? 0;

                                return Text(
                                  data['lastMessage']?.toString().isNotEmpty ==
                                      true
                                      ? data['lastMessage']
                                      : 'Say hi 👋',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: unread > 0
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: unread > 0
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      /// ⏰ TIME + 🔴 BADGE
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(data['lastMessageTime']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),

                          const SizedBox(height: 6),

                          /// 🔴 UNREAD BADGE
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('chats')
                                .doc(doc.id)
                                .collection('messages')
                                .where('isRead', isEqualTo: false)
                                .where('senderEmail',
                                isNotEqualTo: user.email)
                                .snapshots(),
                            builder: (context, snap) {
                              if (!snap.hasData ||
                                  snap.data!.docs.isEmpty) {
                                return const SizedBox();
                              }

                              final count = snap.data!.docs.length;

                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  count > 9 ? '9+' : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final time = ts.toDate();
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}