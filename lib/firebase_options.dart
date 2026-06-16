// Généré par FlutterFire CLI — exécute: flutterfire configure
// Voir: https://firebase.google.com/docs/flutter/setup
//
// ÉTAPES D'INSTALLATION:
// 1. Crée un projet Firebase sur https://console.firebase.google.com
// 2. Active Authentication > Phone
// 3. Active Cloud Firestore
// 4. Active Cloud Messaging
// 5. Installe FlutterFire CLI: dart pub global activate flutterfire_cli
// 6. Exécute: flutterfire configure --project=TON_PROJECT_ID
// 7. Ce fichier sera régénéré automatiquement avec les vraies valeurs

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.'
        );
    }
  }

  // TODO: Remplace ces valeurs par celles de ton projet Firebase
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
  );
}
