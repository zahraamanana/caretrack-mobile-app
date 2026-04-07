import 'package:flutter/foundation.dart';

class AppLogger {
  const AppLogger._();

  static void info(String message) {
    debugPrint('[CareTrack][INFO] $message');
  }

  static void warning(String message, [Object? error]) {
    final suffix = error == null ? '' : ' | $error';
    debugPrint('[CareTrack][WARN] $message$suffix');
  }

  static void error(String message, Object error, [StackTrace? stackTrace]) {
    debugPrint('[CareTrack][ERROR] $message | $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
