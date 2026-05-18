import 'package:flutter/services.dart';

class RotateHelper {
  static bool _isRotated = false;
  static Future<void> toggleRotation() async {
    if (_isRotated) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _isRotated = !_isRotated;
  }
}
