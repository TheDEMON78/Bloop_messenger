import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bloop_messages';
  static const _channelName = 'Messages';

  Future<void> init() async {
    await _fcm.requestPermission();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _local
        .initialize(const InitializationSettings(android: androidInit));

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
          ),
        );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  Future<String?> getToken() => _fcm.getToken();

  void _showForegroundNotification(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
