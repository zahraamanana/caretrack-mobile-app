import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../config/firebase_project_config.dart';

class FirebaseBootstrapService {
  FirebaseBootstrapService._();

  static final FirebaseBootstrapService instance = FirebaseBootstrapService._();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (!FirebaseProjectConfig.enabled || _isInitialized) {
      return;
    }

    try {
      if (kIsWeb) {
        throw UnsupportedError(
          'Firebase web configuration is local-only and should not be committed.',
        );
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          await Firebase.initializeApp();
          break;
        default:
          throw UnsupportedError(
            'This platform is not configured for local-only Firebase setup.',
          );
      }

      _isInitialized = true;
    } on UnsupportedError catch (error) {
      throw StateError(
        'Firebase is enabled, but local Firebase platform files are missing or unsupported for this platform. Keep google-services.json and platform config files local only. Original error: $error',
      );
    }
  }
}
