// models/export_model.dart
import 'dart:convert';

import 'package:iTen/constants/app_config.dart';
import 'package:iTen/models/animation_model.dart';

class ExportPackage {
  final String version;
  final DateTime exportDate;
  final String deviceName;
  final List<AnimationModel> animations;
  final Map<String, dynamic> metadata;

  ExportPackage({
    required this.animations,
    this.version = '1.0.0',
    DateTime? exportDate,
    this.deviceName = '${AppConfig.appName} Device',
    this.metadata = const {},
  }) : exportDate = exportDate ?? DateTime.now();

  // Factory constructor untuk create dari JSON
  factory ExportPackage.fromJson(Map<String, dynamic> json) {
    final animations = (json['animations'] as List)
        .map((animJson) => AnimationModel.fromList(
              animJson['name'],
              [
                animJson['channelCount'],
                animJson['animationLength'],
                animJson['description'],
                animJson['delayData'],
                ...(animJson['frameData'] as List).cast<String>(),
              ],
            ))
        .toList();

    return ExportPackage(
      version: json['version'] ?? '1.0.0',
      exportDate: DateTime.parse(json['exportDate']),
      deviceName: json['deviceName'] ?? 'iTen Device',
      animations: animations,
      metadata: json['metadata'] ?? {},
    );
  }

  // Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'exportDate': exportDate.toIso8601String(),
      'deviceName': deviceName,
      'animations': animations.map((anim) => anim.toMap()).toList(),
      'metadata': metadata,
      'totalAnimations': animations.length,
      'totalFrames': animations.fold(0, (sum, anim) => sum + anim.totalFrames),
    };
  }

  // Convert ke string JSON
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Validasi package
  bool get isValid {
    return animations.isNotEmpty && animations.every((anim) => anim.isValid);
  }

  // Get summary info
  String get summary {
    return 'Export Package: $deviceName | '
           'Animations: ${animations.length} | '
           'Total Frames: ${animations.fold(0, (sum, anim) => sum + anim.totalFrames)} | '
           'Exported: ${exportDate.toLocal()}';
  }

  @override
  String toString() {
    return 'ExportPackage(\n'
        '  version: $version,\n'
        '  deviceName: $deviceName,\n'
        '  exportDate: $exportDate,\n'
        '  animations: ${animations.length},\n'
        '  metadata: $metadata\n'
        ')';
  }
}