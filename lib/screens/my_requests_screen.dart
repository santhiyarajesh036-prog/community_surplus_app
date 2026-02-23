import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

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
        title: const Text('My Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('requesterEmail', isEqualTo: user.email)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState();
          }

          final requests = snapshot.data!.docs;

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final data =
                requests[index].data() as Map<String, dynamic>;
                final status = data['status'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _statusIcon(status),
                    title: Text(
                      data['itemName'] ?? 'Item',
                      style:
                      const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Donor: ${data['donorEmail']}'),
                        const SizedBox(height: 6),
                        _statusChip(status),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Empty UI
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.assignment_outlined,
              size: 80, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No requests yet',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Status Icon
  Widget _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return const Icon(Icons.check_circle,
            color: Colors.green, size: 32);
      case 'rejected':
        return const Icon(Icons.cancel,
            color: Colors.red, size: 32);
      default:
        return const Icon(Icons.hourglass_top,
            color: Colors.orange, size: 32);
    }
  }

  /// Status Chip
  Widget _statusChip(String status) {
    switch (status) {
      case 'approved':
        return const Chip(
          label: Text('Approved', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        );
      case 'rejected':
        return const Chip(
          label: Text('Rejected', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        );
      default:
        return const Chip(
          label: Text('Pending', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.orange,
        );
    }
  }
}
