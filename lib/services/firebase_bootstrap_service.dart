import 'package:firebase_core/firebase_core.dart';

import '../config/firebase_project_config.dart';
import '../firebase_options.dart';

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
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } on UnsupportedError catch (error) {
      throw StateError(
        'Firebase is enabled in FirebaseProjectConfig, but firebase_options.dart is still the placeholder file. Run `flutterfire configure` first. Original error: $error',
      );
    }
  }
}
