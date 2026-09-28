import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_user.dart';
import '../repositories/notification_repository.dart';
import '../repositories/user_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Push notifications via Firebase Cloud Messaging. Foreground messages are
/// also saved to the local notifications table so they show in the bell list.
class FcmService {
  final UserRepository _users;
  final NotificationRepository _notifications;
  StreamSubscription<RemoteMessage>? _sub;

  FcmService(this._users, this._notifications);

  Future<void> start(AppUser user, void Function() onNewMessage) async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) await _users.saveFcmToken(user.uid, token);

    // Lets you target everyone of a role from the Firebase console.
    await messaging.subscribeToTopic('role_${user.role}');

    await _sub?.cancel();
    _sub = FirebaseMessaging.onMessage.listen((m) async {
      final n = m.notification;
      if (n == null) return;
      await _notifications.add(
        user.uid,
        n.title ?? 'Notification',
        n.body ?? '',
      );
      onNewMessage();
    });
  }

  Future<void> stop(AppUser user) async {
    await _sub?.cancel();
    _sub = null;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(
        'role_${user.role}',
      );
    } catch (_) {}
  }
}
