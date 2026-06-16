import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import 'firestore_service.dart';

const _prefKeyUid = 'bg_uid';
const kPrefKeyOpenConv = 'open_conversation_id';
const _msgChannelId = 'bloop_messages';
const _msgChannelName = 'Messages';
const _svcChannelId = 'bloop_background';

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Low-importance channel for the persistent service notification
  final local = FlutterLocalNotificationsPlugin();
  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _svcChannelId,
        'Bloop',
        importance: Importance.min,
      ));

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _bgEntryPoint,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: _svcChannelId,
      initialNotificationTitle: 'Bloop',
      initialNotificationContent: 'Surveillance des messages',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

/// Called from AuthProvider when UID is known (login or app restart)
Future<void> notifyServiceUid(String uid) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefKeyUid, uid);
  FlutterBackgroundService().invoke('setUid', {'uid': uid});
}

/// Called from AuthProvider on sign-out
Future<void> notifyServiceSignOut() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_prefKeyUid);
  FlutterBackgroundService().invoke('clearUid');
}

@pragma('vm:entry-point')
void _bgEntryPoint(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform);

  final local = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await local
      .initialize(const InitializationSettings(android: androidInit));
  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        _msgChannelId,
        _msgChannelName,
        importance: Importance.high,
      ));

  service.on('stopService').listen((_) => service.stopSelf());

  StreamSubscription? convSub;
  final Map<String, int> lastSeen = {};

  Future<void> startListening(String uid) async {
    convSub?.cancel();
    lastSeen.clear();
    convSub =
        FirestoreService().conversationsStream(uid).listen((convs) async {
      final prefs = await SharedPreferences.getInstance();
      final openConvId = prefs.getString(kPrefKeyOpenConv);

      for (final conv in convs) {
        final newTime = conv.lastMessageTime?.millisecondsSinceEpoch;
        final prevTime = lastSeen[conv.id];
        final senderId = conv.lastMessageSenderId;

        if (newTime != null &&
            prevTime != null &&
            newTime > prevTime &&
            senderId != null &&
            senderId != uid &&
            conv.id != openConvId) {
          final senderName = conv.participantNames[senderId];
          final title = conv.isGroup
              ? '${conv.groupName ?? "Groupe"} · ${senderName ?? "Bloop"}'
              : senderName ?? 'Bloop';

          await local.show(
            conv.id.hashCode,
            title,
            conv.lastMessage ?? '',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                _msgChannelId,
                _msgChannelName,
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
        if (newTime != null) lastSeen[conv.id] = newTime;
      }
    });
  }

  service.on('setUid').listen((data) async {
    final uid = data?['uid'] as String?;
    if (uid != null && uid.isNotEmpty) {
      await startListening(uid);
    }
  });

  service.on('clearUid').listen((_) {
    convSub?.cancel();
    lastSeen.clear();
  });

  // Restore UID from SharedPreferences (e.g. after device boot)
  final prefs = await SharedPreferences.getInstance();
  final savedUid = prefs.getString(_prefKeyUid);
  if (savedUid != null && savedUid.isNotEmpty) {
    await startListening(savedUid);
  }
}
