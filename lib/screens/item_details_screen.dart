import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item_model.dart';
import '../data/request_repository.dart';
import 'donor_requests_screen.dart';
import 'full_image_view.dart';

class ItemDetailsScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailsScreen({
    super.key,
    required this.item,
  });

  bool get isExpired {
    if (item.expiryAt == null) return false;
    return DateTime.now().isAfter(item.expiryAt!);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userEmail = currentUser?.email;
    final isDonor = userEmail == item.donorEmail;
    final expired = isExpired || item.status != 'available';

    final alreadyRequestedStream = FirebaseFirestore.instance
        .collection('requests')
        .where('itemId', isEqualTo: item.id)
        .where('requesterEmail', isEqualTo: userEmail)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼 IMAGE (FIXED)
            /// 🖼 ITEM IMAGE (FULL VIEW + TAP)
            if (item.imagePath != null && File(item.imagePath!).existsSync())
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullImageView(
                        imageFile: File(item.imagePath!),
                      ),
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.imagePath!),
                      fit: BoxFit.contain, // ✅ FULL IMAGE
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              )
            else
              _imagePlaceholder(),


            const SizedBox(height: 20),

            /// ITEM NAME
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// PRICE
            Text(
              item.isFree ? 'Free' : '₹ ${item.price.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 18,
                color: item.isFree ? Colors.green : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            /// STATUS
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                _statusChip(item.status),
              ],
            ),

            /// EXPIRY
            if (item.expiryAt != null) ...[
              const SizedBox(height: 10),
              Builder(
                builder: (_) {
                  final expiry = item.expiryAt!.toLocal();
                  return Text(
                    'Expiry: ${expiry.day}/${expiry.month}/${expiry.year} '
                        '${expiry.hour.toString().padLeft(2, '0')}:'
                        '${expiry.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isExpired ? Colors.red : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            /// DONOR
            Text(
              'Donated by',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              item.donorEmail,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 24),

            /// DONOR BUTTON
            if (isDonor)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.queue),
                  label: const Text('View Request Queue'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DonorRequestsScreen(itemId: item.id),
                      ),
                    );
                  },
                ),
              ),

            /// REQUEST BUTTON
            if (!isDonor)
              StreamBuilder<QuerySnapshot>(
                stream: alreadyRequestedStream,
                builder: (context, snapshot) {
                  final alreadyRequested =
                      snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: expired || alreadyRequested
                          ? null
                          : () async {
                        await RequestRepository.addRequest(
                          itemId: item.id,
                          itemName: item.name,
                          requesterEmail: userEmail!,
                          donorEmail: item.donorEmail,
                        );

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                            Text('Request sent successfully'),
                          ),
                        );
                      },
                      child: Text(
                        alreadyRequested
                            ? 'Already Requested'
                            : expired
                            ? 'Not Available'
                            : 'Request Item',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_not_supported, size: 48),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'claimed':
        color = Colors.blue;
        break;
      case 'expired':
        color = Colors.red;
        break;
      default:
        color = Colors.green;
    }

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
