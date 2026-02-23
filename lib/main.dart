import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/splash_screen.dart';
import 'services/fcm_service.dart';
import 'services/user_status_service.dart';

/// 🔔 Needed to open screen from notification
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 Handle notification tap when app opened
  await FCMService.setupInteractedMessage(navigatorKey);

  runApp(
    const PresenceHandler(
      child: MyApp(),
    ),
  );
}

/// 🟢 PRESENCE HANDLER
class PresenceHandler extends StatefulWidget {
  final Widget child;
  const PresenceHandler({super.key, required this.child});

  @override
  State<PresenceHandler> createState() => _PresenceHandlerState();
}

class _PresenceHandlerState extends State<PresenceHandler>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    UserStatusService.setOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UserStatusService.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      UserStatusService.setOnline();
    } else {
      UserStatusService.setOffline();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Community Surplus',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}