import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firestore_service.dart';

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // Background messages are shown by FCM automatically on Android
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bloop_messages';
  static const _channelName = 'Messages';

  Future<void> init(String uid) async {
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

    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Save token to Firestore so Cloud Functions can reach this device
    final token = await _fcm.getToken();
    if (token != null) {
      await FirestoreService().saveFcmToken(uid, token);
    }
    // Refresh token when it changes
    _fcm.onTokenRefresh.listen((newToken) {
      FirestoreService().saveFcmToken(uid, newToken);
    });
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

