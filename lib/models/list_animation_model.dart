// models/list_animation_model.dart
import 'dart:convert';

import 'animation_model.dart';

class ListAnimationModel {
  final List<AnimationModel> animations;
  final String source; // 'BZL' atau 'SYSTEMBZL'
  final DateTime lastSync;

  ListAnimationModel({
    required this.animations,
    required this.source,
    required this.lastSync,
  });

  // models/list_animation_model.dart
factory ListAnimationModel.fromFirebaseData(String nodeName, Map<String, dynamic> data) {
  final animations = <AnimationModel>[];
  
  print('🔍 ListAnimationModel.fromFirebaseData:');
  print('   - Node: $nodeName');
  print('   - Data keys: ${data.keys}');
  print('   - Data length: ${data.length}');
  
  data.forEach((key, value) {
  print('   - Processing key: $key');
  print('   - Value type: ${value.runtimeType}');
  print('   - Value: $value');

  try {
    List<dynamic> parsedList;

    // ✅ Handle null dan string kosong
    if (value == null) {
      print('   - ⚠️ Value is null, replacing with "-"');
      parsedList = ["-"];
    } else if (value is String) {
      if (value.trim().isEmpty) {
        print('   - ⚠️ Empty string detected, replacing with "-"');
        parsedList = ["-"];
      } else {
        try {
          print('   - 🔄 Parsing String as JSON...');
          final decoded = jsonDecode(value);
          if (decoded is List) {
            parsedList = decoded;
            print('   - ✅ Successfully parsed String to List');
          } else {
            print('   - ⚠️ JSON is not a List, replacing with "-"');
            parsedList = ["-"];
          }
        } catch (e) {
          print('   - ❌ Failed to parse JSON: $e, replacing with "-"');
          parsedList = ["-"];
        }
      }
    } else if (value is List) {
      parsedList = value;
      print('   - ✅ Value is already List');
    } else {
      print('   - ⚠️ Unsupported value type (${value.runtimeType}), replacing with "-"');
      parsedList = ["-"];
    }

    // ✅ Sekarang parsedList dijamin terisi (tidak null)
    final animation = AnimationModel.fromList(key, parsedList);
    animations.add(animation);
    print('   - ✅ Success: ${animation.name}');

  } catch (e) {
    print('   - ❌ Error parsing animation $key: $e');
    print('   - Stack trace: ${e.toString()}');
  }
});


  print('🔍 Parsing result:');
  print('   - Total animations parsed: ${animations.length}');
  
  return ListAnimationModel(
    animations: animations,
    source: nodeName,
    lastSync: DateTime.now(),
  );
}

  // Factory constructor dari List biasa
  factory ListAnimationModel.fromList(List<AnimationModel> animations, String source) {
    return ListAnimationModel(
      animations: animations,
      source: source,
      lastSync: DateTime.now(),
    );
  }

  // Factory constructor empty
  factory ListAnimationModel.empty(String source) {
    return ListAnimationModel(
      animations: [],
      source: source,
      lastSync: DateTime.now(),
    );
  }

  // ============ BASIC LIST OPERATIONS ============

  // Get total animations
  int get length => animations.length;

  // Check if empty
  bool get isEmpty => animations.isEmpty;

  // Check if not empty
  bool get isNotEmpty => animations.isNotEmpty;

  // Get animation by index
  AnimationModel operator [](int index) => animations[index];

  // Get animation by name
  AnimationModel? getByName(String name) {
    try {
      return animations.firstWhere((animation) => animation.name == name);
    } catch (e) {
      return null;
    }
  }

  // Check if contains animation name
  bool containsName(String name) {
    return animations.any((animation) => animation.name == name);
  }

  // Get animation index by name
  int indexOfName(String name) {
    return animations.indexWhere((animation) => animation.name == name);
  }

  // ============ FILTER OPERATIONS ============

  // Filter by channel count
  ListAnimationModel filterByChannel(int channelCount) {
    final filtered = animations.where((animation) => animation.channelCount == channelCount).toList();
    return ListAnimationModel.fromList(filtered, '$source (Channel $channelCount)');
  }

  // Filter by animation length
  ListAnimationModel filterByLength(int minLength, [int? maxLength]) {
    final filtered = animations.where((animation) {
      if (maxLength != null) {
        return animation.animationLength >= minLength && animation.animationLength <= maxLength;
      }
      return animation.animationLength >= minLength;
    }).toList();
    
    final rangeText = maxLength != null ? '$minLength-$maxLength' : '≥$minLength';
    return ListAnimationModel.fromList(filtered, '$source (Length $rangeText)');
  }

  // Filter by frame count
  ListAnimationModel filterByFrameCount(int minFrames, [int? maxFrames]) {
    final filtered = animations.where((animation) {
      if (maxFrames != null) {
        return animation.totalFrames >= minFrames && animation.totalFrames <= maxFrames;
      }
      return animation.totalFrames >= minFrames;
    }).toList();
    
    final rangeText = maxFrames != null ? '$minFrames-$maxFrames' : '≥$minFrames';
    return ListAnimationModel.fromList(filtered, '$source (Frames $rangeText)');
  }

  // Filter valid animations only
  ListAnimationModel get validAnimations {
    final filtered = animations.where((animation) => animation.isValid).toList();
    return ListAnimationModel.fromList(filtered, '$source (Valid Only)');
  }

  // Filter by search term
  ListAnimationModel search(String term) {
    final filtered = animations.where((animation) {
      return animation.name.toLowerCase().contains(term.toLowerCase()) ||
             animation.description.toLowerCase().contains(term.toLowerCase());
    }).toList();
    
    return ListAnimationModel.fromList(filtered, '$source (Search: "$term")');
  }

  // ============ SORT OPERATIONS ============

  // Sort by name
  ListAnimationModel sortByName({bool ascending = true}) {
    final sorted = List<AnimationModel>.from(animations);
    sorted.sort((a, b) => ascending 
        ? a.name.compareTo(b.name)
        : b.name.compareTo(a.name));
    return ListAnimationModel.fromList(sorted, '$source (Sorted by Name)');
  }

  // Sort by channel count
  ListAnimationModel sortByChannel({bool ascending = true}) {
    final sorted = List<AnimationModel>.from(animations);
    sorted.sort((a, b) => ascending 
        ? a.channelCount.compareTo(b.channelCount)
        : b.channelCount.compareTo(a.channelCount));
    return ListAnimationModel.fromList(sorted, '$source (Sorted by Channel)');
  }

  // Sort by animation length
  ListAnimationModel sortByLength({bool ascending = true}) {
    final sorted = List<AnimationModel>.from(animations);
    sorted.sort((a, b) => ascending 
        ? a.animationLength.compareTo(b.animationLength)
        : b.animationLength.compareTo(a.animationLength));
    return ListAnimationModel.fromList(sorted, '$source (Sorted by Length)');
  }

  // Sort by frame count
  ListAnimationModel sortByFrameCount({bool ascending = true}) {
    final sorted = List<AnimationModel>.from(animations);
    sorted.sort((a, b) => ascending 
        ? a.totalFrames.compareTo(b.totalFrames)
        : b.totalFrames.compareTo(a.totalFrames));
    return ListAnimationModel.fromList(sorted, '$source (Sorted by Frames)');
  }

  // ============ STATISTICS OPERATIONS ============

  // Get total frames across all animations
  int get totalFrames {
    return animations.fold(0, (sum, animation) => sum + animation.totalFrames);
  }

  // Get average frames per animation
  double get averageFrames {
    if (animations.isEmpty) return 0;
    return totalFrames / animations.length;
  }

  // Get channel count distribution
  Map<int, int> get channelDistribution {
    final distribution = <int, int>{};
    for (final animation in animations) {
      distribution[animation.channelCount] = (distribution[animation.channelCount] ?? 0) + 1;
    }
    return distribution;
  }

  // Get length distribution
  Map<int, int> get lengthDistribution {
    final distribution = <int, int>{};
    for (final animation in animations) {
      distribution[animation.animationLength] = (distribution[animation.animationLength] ?? 0) + 1;
    }
    return distribution;
  }

  // Get valid animations count
  int get validCount {
    return animations.where((animation) => animation.isValid).length;
  }

  // Get invalid animations count
  int get invalidCount {
    return animations.where((animation) => !animation.isValid).length;
  }

  // ============ BATCH OPERATIONS ============

  // Add animation
  ListAnimationModel addAnimation(AnimationModel animation) {
    final newList = List<AnimationModel>.from(animations);
    newList.add(animation);
    return ListAnimationModel.fromList(newList, source);
  }

  // Add multiple animations
  ListAnimationModel addAnimations(List<AnimationModel> newAnimations) {
    final newList = List<AnimationModel>.from(animations);
    newList.addAll(newAnimations);
    return ListAnimationModel.fromList(newList, source);
  }

  // Remove animation by name
  ListAnimationModel removeAnimation(String name) {
    final newList = animations.where((animation) => animation.name != name).toList();
    return ListAnimationModel.fromList(newList, source);
  }

  // Remove animation by index
  ListAnimationModel removeAt(int index) {
    final newList = List<AnimationModel>.from(animations);
    newList.removeAt(index);
    return ListAnimationModel.fromList(newList, source);
  }

  // Update animation by name
  ListAnimationModel updateAnimation(String name, AnimationModel newAnimation) {
    final newList = animations.map((animation) {
      return animation.name == name ? newAnimation : animation;
    }).toList();
    return ListAnimationModel.fromList(newList, source);
  }

  // Clear all animations
  ListAnimationModel clear() {
    return ListAnimationModel.fromList([], '$source (Cleared)');
  }

  // ============ CONVERSION OPERATIONS ============

  // Convert to Map untuk Firebase
  Map<String, dynamic> toFirebaseMap() {
    final map = <String, dynamic>{};
    for (final animation in animations) {
      map[animation.name] = animation.toList();
    }
    return map;
  }

  // Convert to List of Maps untuk display
  List<Map<String, dynamic>> toMapList() {
    return animations.map((animation) => animation.toMap()).toList();
  }

  // Get list of animation names
  List<String> get names {
    return animations.map((animation) => animation.name).toList();
  }

  // Get list of animation summaries
  List<String> get summaries {
    return animations.map((animation) => animation.summary).toList();
  }

  // ============ UTILITY METHODS ============

  // Get summary info
  String get summary {
    return 'ListAnimationModel: $source | '
           'Animations: ${animations.length} ($validCount valid) | '
           'Total Frames: $totalFrames | '
           'Last Sync: ${lastSync.toLocal()}';
  }

  // Get detailed statistics
  Map<String, dynamic> get statistics {
    return {
      'source': source,
      'totalAnimations': animations.length,
      'validAnimations': validCount,
      'invalidAnimations': invalidCount,
      'totalFrames': totalFrames,
      'averageFrames': averageFrames,
      'channelDistribution': channelDistribution,
      'lengthDistribution': lengthDistribution,
      'lastSync': lastSync.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'ListAnimationModel(\n'
        '  source: $source,\n'
        '  animations: ${animations.length},\n'
        '  valid: $validCount,\n'
        '  totalFrames: $totalFrames,\n'
        '  lastSync: $lastSync\n'
        ')';
  }

  // Iterator untuk for-in loops
  Iterator<AnimationModel> get iterator => animations.iterator;

  // ForEach method
  void forEach(void Function(AnimationModel) action) {
    animations.forEach(action);
  }

  // Map method
  List<R> map<R>(R Function(AnimationModel) convert) {
    return animations.map(convert).toList();
  }

  // Where method
  ListAnimationModel where(bool Function(AnimationModel) test) {
    final filtered = animations.where(test).toList();
    return ListAnimationModel.fromList(filtered, '$source (Filtered)');
  }

  // Take method
  ListAnimationModel take(int count) {
    final taken = animations.take(count).toList();
    return ListAnimationModel.fromList(taken, '$source (First $count)');
  }

  // Skip method
  ListAnimationModel skip(int count) {
    final skipped = animations.skip(count).toList();
    return ListAnimationModel.fromList(skipped, '$source (After $count)');
  }
}

// Extension untuk copyWith di ListAnimationModel
extension ListAnimationModelExtension on ListAnimationModel {
  ListAnimationModel copyWith({
    List<AnimationModel>? animations,
    String? source,
    DateTime? lastSync,
  }) {
    return ListAnimationModel(
      animations: animations ?? this.animations,
      source: source ?? this.source,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}