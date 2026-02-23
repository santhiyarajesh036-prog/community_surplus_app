import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/notifications_screen.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// MAIN SETUP
  static Future<void> setupInteractedMessage(
      GlobalKey<NavigatorState> navigatorKey) async {

    // 1️⃣ Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("PERMISSION: ${settings.authorizationStatus}");

    // 2️⃣ Get token & save to Firestore
    await _saveTokenToDatabase();

    // 3️⃣ Token refresh (important when reinstall / clear data)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveTokenToDatabase(newToken);
    });

    // 4️⃣ Foreground notification (app open)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("FOREGROUND MESSAGE: ${message.notification?.title}");
    });

    // 5️⃣ App opened from terminated
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _openNotifications(navigatorKey);
    }

    // 6️⃣ App opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _openNotifications(navigatorKey);
    });
  }

  /// SAVE TOKEN TO FIRESTORE
  static Future<void> _saveTokenToDatabase([String? newToken]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token = newToken ?? await _messaging.getToken();

    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({'fcmToken': token}, SetOptions(merge: true));

    print("TOKEN SAVED FOR USER: ${user.email}");
  }

  /// OPEN NOTIFICATIONS PAGE
  static void _openNotifications(GlobalKey<NavigatorState> navigatorKey) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
