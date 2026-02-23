import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'request_screen.dart';
import 'my_donations_screen.dart';
import 'profile_screen.dart';
import 'donate_screen.dart';
import 'my_chats_screen.dart';
import 'my_requests_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  /// 🔔 FIXED UNREAD COUNT STREAM
  Stream<int> unreadCountStream() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('toEmail', isEqualTo: email)   // ✅ FIXED FIELD
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      /// 🔷 APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        elevation: 0,
        title: const Text(
          "Home",
          style: TextStyle(color: Colors.white),
        ),
        actions: [

          /// 🔔 NOTIFICATION ICON WITH LIVE BADGE
          StreamBuilder<int>(
            stream: unreadCountStream(),
            builder: (context, snapshot) {

              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),

                  /// 🔴 RED BADGE
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          /// ⋮ MENU
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      /// 🔷 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Welcome 👋",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            _homeCard(
              title: "Donate Item",
              icon: Icons.volunteer_activism,
              colors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DonateScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            _homeCard(
              title: "Request Item",
              icon: Icons.search,
              colors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RequestScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            _homeCard(
              title: "My Chats",
              icon: Icons.chat_bubble_outline,
              colors: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyChatsScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            _homeCard(
              title: "My Donations",
              icon: Icons.inventory,
              colors: const [Color(0xFF0F766E), Color(0xFF14B8A6)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyDonationsScreen()),
                );
              },
            ),

            const SizedBox(height: 20),

            _homeCard(
              title: "My Requests",
              icon: Icons.assignment,
              colors: const [Color(0xFF2563EB), Color(0xFF1E40AF)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🧩 CARD UI
  Widget _homeCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }
}