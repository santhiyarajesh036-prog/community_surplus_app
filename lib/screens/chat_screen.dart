import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    listenAndMarkRead();
  }

  /// 🔥 AUTO READ WHEN NEW MESSAGE ARRIVES
  void listenAndMarkRead() {
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) async {
      final batch = FirebaseFirestore.instance.batch();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['senderEmail'] != user!.email) {
          batch.update(doc.reference, {'isRead': true});
        }
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    });
  }

  /// 📤 SEND MESSAGE + 🔔 CREATE NOTIFICATION
  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || user == null) return;

    final chatRef =
    FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    /// 1️⃣ Add message
    await chatRef.collection('messages').add({
      'text': text,
      'senderEmail': user!.email,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    /// 2️⃣ Update last message preview (IMPORTANT FIXED FIELD NAME)
    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    /// 3️⃣ Get receiver email
    final chatDoc = await chatRef.get();
    final participants = List<String>.from(chatDoc['participants']);
    final receiverEmail =
    participants.firstWhere((e) => e != user!.email);

    /// 4️⃣ Create notification 🔔
    await FirebaseFirestore.instance.collection('notifications').add({
      'toEmail': receiverEmail,
      'fromEmail': user!.email,
      'title': 'New Message',
      'message': text,
      'chatId': widget.chatId,
      'type': 'chat_message',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    _messageController.clear();
  }

  /// ⏰ FORMAT TIME
  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return TimeOfDay.fromDateTime(date).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          /// 💬 MESSAGE LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;

                    final bool isMe =
                        data['senderEmail'] == user?.email;

                    final bool isRead = data['isRead'] ?? false;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blue.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              data['text'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  formatTime(data['createdAt']),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(width: 4),
                                if (isMe)
                                  Icon(
                                    isRead
                                        ? Icons.done_all
                                        : Icons.done,
                                    size: 16,
                                    color: isRead
                                        ? Colors.blue
                                        : Colors.grey,
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
          ),

          /// ✍️ INPUT BOX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}