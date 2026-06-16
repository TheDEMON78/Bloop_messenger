// Généré depuis Firebase Console — projet: bloop-messenger-95ea3
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ne supporte pas cette plateforme.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkXeRyggJ_qpGIEKiePyqf7AbJ3mHht1s',
    appId: '1:915883399522:android:09123f86f5022db3d7743b',
    messagingSenderId: '915883399522',
    projectId: 'bloop-messenger-95ea3',
    storageBucket: 'bloop-messenger-95ea3.firebasestorage.app',
  );
}
