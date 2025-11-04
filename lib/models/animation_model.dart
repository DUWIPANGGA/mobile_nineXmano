// models/animation_model.dart
class AnimationModel {
  final String name;
  final int channelCount;
  final int animationLength;
  final String description;
  final String delayData;
  final List<String> frameData;

  AnimationModel({
    required this.name,
    required this.channelCount,
    required this.animationLength,
    required this.description,
    required this.delayData,
    required this.frameData,
  });

  // Factory constructor untuk create object dari List dynamic
  factory AnimationModel.fromList(String animationName, List<dynamic> data) {
    return AnimationModel(
      name: animationName,
      channelCount: _parseInt(data[0]),
      animationLength: _parseInt(data[1]),
      description: data[2]?.toString() ?? '',
      delayData: data[3]?.toString() ?? '',
      frameData: _parseFrameData(data.sublist(4)),
    );
  }

  // Helper method untuk parse integer
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper method untuk parse frame data
  static List<String> _parseFrameData(List<dynamic> frameList) {
    return frameList.map((frame) => frame?.toString() ?? '').toList();
  }

  // Convert object ke Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'channelCount': channelCount,
      'animationLength': animationLength,
      'description': description,
      'delayData': delayData,
      'frameData': frameData,
      'frameCount': frameData.length,
    };
  }

  // Convert object ke List format untuk Firebase
  List<dynamic> toList() {
    return [
      channelCount.toString(),
      animationLength.toString(),
      description,
      delayData,
      ...frameData,
    ];
  }

  // Copy with method untuk update data
  AnimationModel copyWith({
    String? name,
    int? channelCount,
    int? animationLength,
    String? description,
    String? delayData,
    List<String>? frameData,
  }) {
    return AnimationModel(
      name: name ?? this.name,
      channelCount: channelCount ?? this.channelCount,
      animationLength: animationLength ?? this.animationLength,
      description: description ?? this.description,
      delayData: delayData ?? this.delayData,
      frameData: frameData ?? this.frameData,
    );
  }

  // Get total frames
  int get totalFrames => frameData.length;

  // Get delay untuk frame tertentu
  String getDelayForFrame(int frameIndex) {
    if (frameIndex >= 0 && frameIndex < delayData.length) {
      return delayData[frameIndex];
    }
    return '0';
  }

  // Get frame data untuk frame tertentu
  String getFrameData(int frameIndex) {
    if (frameIndex >= 0 && frameIndex < frameData.length) {
      return frameData[frameIndex];
    }
    return '';
  }

  // Validasi data animasi
  bool get isValid {
    return channelCount > 0 &&
        animationLength > 0 &&
        delayData.isNotEmpty &&
        frameData.isNotEmpty &&
        frameData.every((frame) => frame.isNotEmpty);
  }

  // Get summary info
  String get summary {
    return 'Animation: $name | Channels: $channelCount | Length: $animationLength | Frames: $totalFrames';
  }

  @override
  String toString() {
    return 'AnimationModel(\n'
        '  name: $name,\n'
        '  channelCount: $channelCount,\n'
        '  animationLength: $animationLength,\n'
        '  description: $description,\n'
        '  delayData: $delayData,\n'
        '  frameData: [${frameData.length} frames]\n'
        ')';
  }

  // Method untuk debug details
  String toDetailedString() {
    final buffer = StringBuffer();
    buffer.writeln('Animation: $name');
    buffer.writeln('Channels: $channelCount');
    buffer.writeln('Length: $animationLength');
    buffer.writeln('Description: $description');
    buffer.writeln('Delay Data: $delayData');
    buffer.writeln('Total Frames: ${frameData.length}');
    buffer.writeln('Frames:');
    for (int i = 0; i < frameData.length; i++) {
      buffer.writeln('  Frame ${i + 1}: ${frameData[i]}');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimationModel &&
        other.name == name &&
        other.channelCount == channelCount &&
        other.animationLength == animationLength &&
        other.description == description &&
        other.delayData == delayData &&
        other.frameData.length == frameData.length;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        channelCount.hashCode ^
        animationLength.hashCode ^
        description.hashCode ^
        delayData.hashCode ^
        frameData.length.hashCode;
  }
}