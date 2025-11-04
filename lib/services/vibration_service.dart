import 'package:vibration/vibration.dart';

class VibrationService {
  static final VibrationService _instance = VibrationService._internal();
  factory VibrationService() => _instance;
  VibrationService._internal();

  bool _hasVibrator = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
      _isInitialized = true;
      print('✅ Vibration Service Initialized');
    } catch (e) {
      print('❌ Vibration Initialization Error: $e');
      _hasVibrator = false;
      _isInitialized = true;
    }
  }

  /// Vibrate dengan durasi custom (default: 500ms)
  Future<void> vibrate([int duration = 500]) async {
    if (!_hasVibrator || !_isInitialized) return;
    
    try {
      await Vibration.vibrate(duration: duration);
      print('📳 Vibrated for ${duration}ms');
    } catch (e) {
      print('❌ Vibration failed: $e');
    }
  }

  /// Vibrate pendek (200ms)
  Future<void> vibrateMiddle() async {
    await vibrate(200);
  }

  /// Vibrate panjang (1000ms)
  Future<void> vibrateLong() async {
    await vibrate(1000);
  }

  /// Check if vibration is available
  bool get canVibrate => _hasVibrator && _isInitialized;
}