// services/default_animations_service.dart
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/services/preferences_service.dart';

class DefaultAnimationsService {
  static final DefaultAnimationsService _instance =
      DefaultAnimationsService._internal();
  factory DefaultAnimationsService() => _instance;
  DefaultAnimationsService._internal();

  final PreferencesService _preferencesService = PreferencesService();

  // Data animasi default
  static const List<Map<String, dynamic>> _defaultAnimationsData = [
    {
      'name': 'Animation 01 - AUTO',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Automatic animation sequence',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 02 - AUTO ALL BUILTIN',
      'channelCount': 4,
      'animationLength': 15,
      'description': 'All built-in automatic animations',
      'delayData': '150',
      'frameData': [],
    },
    {
      'name': 'Animation 03 - Baling - Baling',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'Propeller rotation effect',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 04 - X Loop',
      'channelCount': 4,
      'animationLength': 12,
      'description': 'X pattern looping animation',
      'delayData': '120',
      'frameData': [],
    },
    {
      'name': 'Animation 05 - X Run',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'X pattern running effect',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 06 - Baling Kedip',
      'channelCount': 4,
      'animationLength': 6,
      'description': 'Blinking propeller effect',
      'delayData': '60',
      'frameData': [],
    },
    {
      'name': 'Animation 07 - Left Right',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'Left to right movement',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 08 - Random Bit',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Random bit pattern animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 09 - Swap Fill',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'Swap and fill animation',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 10 - Every 2 Bit',
      'channelCount': 4,
      'animationLength': 12,
      'description': 'Every second bit animation',
      'delayData': '120',
      'frameData': [],
    },
    {
      'name': 'Animation 11 - Swap Fill LR',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Left-right swap fill animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 12 - Up Run',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'Upward running animation',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 13 - Up Down Run',
      'channelCount': 4,
      'animationLength': 12,
      'description': 'Up-down running animation',
      'delayData': '120',
      'frameData': [],
    },
    {
      'name': 'Animation 14 - Blinking LR',
      'channelCount': 4,
      'animationLength': 6,
      'description': 'Left-right blinking animation',
      'delayData': '60',
      'frameData': [],
    },
    {
      'name': 'Animation 15 - Blinking UD',
      'channelCount': 4,
      'animationLength': 6,
      'description': 'Up-down blinking animation',
      'delayData': '60',
      'frameData': [],
    },
    {
      'name': 'Animation 16 - Random Corner',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Random corner animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 17 - Fill Circle',
      'channelCount': 4,
      'animationLength': 15,
      'description': 'Circular fill animation',
      'delayData': '150',
      'frameData': [],
    },
    {
      'name': 'Animation 18 - X Pulse',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'X pattern pulsing animation',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 19 - X Blink',
      'channelCount': 4,
      'animationLength': 6,
      'description': 'X pattern blinking animation',
      'delayData': '60',
      'frameData': [],
    },
    {
      'name': 'Animation 20 - O Left Right',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'O pattern left-right animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 21 - O LR',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'O pattern left-right simplified',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 22 - O Out',
      'channelCount': 4,
      'animationLength': 12,
      'description': 'O pattern outward animation',
      'delayData': '120',
      'frameData': [],
    },
    {
      'name': 'Animation 23 - Sweeper',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Sweeping animation effect',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 24 - In Out',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'In-out animation pattern',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 25 - Bouncing',
      'channelCount': 4,
      'animationLength': 12,
      'description': 'Bouncing animation effect',
      'delayData': '120',
      'frameData': [],
    },
    {
      'name': 'Animation 26 - Bouncing LR',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Left-right bouncing animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 27 - Bouncing Blink',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'Bouncing with blinking effect',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 28 - Fill in',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Fill in animation pattern',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 29 - X swap',
      'channelCount': 4,
      'animationLength': 8,
      'description': 'X pattern swap animation',
      'delayData': '80',
      'frameData': [],
    },
    {
      'name': 'Animation 30 - Fill Right',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Right fill animation',
      'delayData': '100',
      'frameData': [],
    },
    {
      'name': 'Animation 31 - Fill Down',
      'channelCount': 4,
      'animationLength': 10,
      'description': 'Downward fill animation',
      'delayData': '100',
      'frameData': [],
    },
  ];

  // Initialize default animations
  Future<void> initializeDefaultAnimations() async {
    try {
      final existingDefaults = await _preferencesService.getDefaultAnimations();

      // Jika belum ada default animations, buat yang baru
      if (existingDefaults.isEmpty) {
        final defaultAnimations = _createDefaultAnimations();
        await _preferencesService.saveDefaultAnimations(defaultAnimations);
        print(
          '✅ Default animations initialized (${defaultAnimations.length} animations)',
        );
      } else {
        print(
          '✅ Default animations already exist (${existingDefaults.length} animations)',
        );
      }
    } catch (e) {
      print('❌ Error initializing default animations: $e');
    }
  }

  // Create AnimationModel list dari data default
  List<AnimationModel> _createDefaultAnimations() {
    return _defaultAnimationsData.map((data) {
      return AnimationModel(
        name: data['name'] as String,
        channelCount: data['channelCount'] as int,
        animationLength: data['animationLength'] as int,
        description: data['description'] as String,
        delayData: data['delayData'] as String,
        frameData: List<String>.from(data['frameData'] as List),
      );
    }).toList();
  }

  // Get all default animations
  Future<List<AnimationModel>> getDefaultAnimations() async {
    return await _preferencesService.getDefaultAnimations();
  }

  // Check if animation is default
  Future<bool> isDefaultAnimation(String animationName) async {
    return await _preferencesService.isDefaultAnimation(animationName);
  }

  // Get default animation by name
  Future<AnimationModel?> getDefaultAnimationByName(String name) async {
    final defaults = await getDefaultAnimations();
    return defaults.firstWhere((anim) => anim.name == name);
  }
}
