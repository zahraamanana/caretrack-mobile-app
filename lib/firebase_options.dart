import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase Linux is not configured yet for this project.',
        );
      default:
        throw UnsupportedError(
          'This platform is not configured for Firebase.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUoZdzaEm-3O9v1tbqZ-8Ug0lIj688D3c',
    appId: '1:947475772537:android:a6390e1032993535f010a8',
    messagingSenderId: '947475772537',
    projectId: 'caretrack-app-754ab',
    storageBucket: 'caretrack-app-754ab.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAqPnQS9l6t7UidIUmYChu4v-6oA0SI3n8',
    appId: '1:947475772537:web:e5e97720b2769339f010a8',
    messagingSenderId: '947475772537',
    projectId: 'caretrack-app-754ab',
    authDomain: 'caretrack-app-754ab.firebaseapp.com',
    storageBucket: 'caretrack-app-754ab.firebasestorage.app',
    measurementId: 'G-YH446VZWBX',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBT7gH1QBRXXnfZFrpHtjP6wKnYrY0hvVw',
    appId: '1:947475772537:ios:5b933e1bd50537faf010a8',
    messagingSenderId: '947475772537',
    projectId: 'caretrack-app-754ab',
    storageBucket: 'caretrack-app-754ab.firebasestorage.app',
    iosBundleId: 'com.example.uilayout',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBT7gH1QBRXXnfZFrpHtjP6wKnYrY0hvVw',
    appId: '1:947475772537:ios:5b933e1bd50537faf010a8',
    messagingSenderId: '947475772537',
    projectId: 'caretrack-app-754ab',
    storageBucket: 'caretrack-app-754ab.firebasestorage.app',
    iosBundleId: 'com.example.uilayout',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAqPnQS9l6t7UidIUmYChu4v-6oA0SI3n8',
    appId: '1:947475772537:web:32639997c27f4ee2f010a8',
    messagingSenderId: '947475772537',
    projectId: 'caretrack-app-754ab',
    authDomain: 'caretrack-app-754ab.firebaseapp.com',
    storageBucket: 'caretrack-app-754ab.firebasestorage.app',
    measurementId: 'G-Z3GLRD60DM',
  );

}