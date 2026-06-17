import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/contacts_provider.dart';
import 'screens/splash_screen.dart';
import 'services/background_message_service.dart';
import 'services/firestore_service.dart';

final _localNotif = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // FCM setup
  FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
  await FirebaseMessaging.instance.requestPermission();
  await FirebaseMessaging.instance.subscribeToTopic('announcements');

  // Local notifications for foreground FCM messages
  await _localNotif.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  ));
  await _localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'announcements', 'Annonces',
        importance: Importance.high,
      ));

  FirebaseMessaging.onMessage.listen((message) async {
    final n = message.notification;
    if (n == null) return;
    await _localNotif.show(
      message.hashCode,
      n.title,
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'announcements', 'Annonces',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  });

  await initBackgroundService();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
      ],
      child: const BloopMessengerApp(),
    ),
  );
}

ThemeData _darkTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00F5FF),
        onPrimary: Colors.black,
        secondary: Color(0xFF00C4D4),
        onSecondary: Colors.black,
        surface: Color(0xFF0D0D16),
        onSurface: Colors.white,
        surfaceContainer: Color(0xFF1E1E2E),
        surfaceContainerHigh: Color(0xFF1A1A2E),
        outline: Color(0xFF3D3D55),
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D0D16),
        foregroundColor: Color(0xFF00F5FF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF0D0D16),
        indicatorColor: Color(0x2200F5FF),
      ),
      dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1A1A2E)),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        labelStyle: const TextStyle(color: Color(0xFF00F5FF)),
        counterStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.38)),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00F5FF)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF00F5FF), width: 2),
        ),
      ),
    );

ThemeData _lightTheme() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0098A8),
        onPrimary: Colors.white,
        secondary: Color(0xFF007A87),
        onSecondary: Colors.white,
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF1A1A2A),
        surfaceContainer: Color(0xFFEEF1F6),
        surfaceContainerHigh: Color(0xFFE4E8EF),
        outline: Color(0xFFB0B8C8),
        error: Colors.redAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF0098A8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFFFFFFFF),
        indicatorColor: Color(0x220098A8),
      ),
      dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFFE4E8EF)),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Color(0xFFB0B8C8)),
        labelStyle: TextStyle(color: Color(0xFF0098A8)),
        counterStyle: TextStyle(color: Color(0xFFB0B8C8)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0098A8)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF0098A8), width: 2),
        ),
      ),
    );

class BloopMessengerApp extends StatefulWidget {
  const BloopMessengerApp({super.key});

  @override
  State<BloopMessengerApp> createState() => _BloopMessengerAppState();
}

class _BloopMessengerAppState extends State<BloopMessengerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;
    FirestoreService().updatePresence(uid, state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloop',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
        Locale('en'),
      ],
      home: const SplashScreen(),
    );
  }
}
