import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bloop_messages';
  static const _channelName = 'Messages';

  Future<void> init(String uid) async {
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

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _local.show(
      id,
      title,
      body,
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
