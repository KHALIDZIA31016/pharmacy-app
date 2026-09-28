import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'data/services/auth_service.dart';
import 'data/services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authService = AuthService();
  try {
    await Firebase.initializeApp();
    authService.configured = true;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase not configured: $e');
  }
  runApp(PharmacyApp(authService: authService));
}
