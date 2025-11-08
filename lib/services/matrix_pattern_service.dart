// services/matrix_pattern_service.dart

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}

class MatrixPatternService {
  // Calculate optimal grid size for X pattern display
  int calculateOptimalGridSize(int channelCount) {
    final minSize = (channelCount / 2).ceil();
    return minSize + 1; // Add some extra space
  }

  // Generate X pattern positions (same as JavaScript implementation)
  List<Point> generateXPattern(int channelCount) {
    final List<Point> xPattern = [];
    final totalChannels = channelCount;
    final segment = totalChannels ~/ 4;

    // Same pattern as JavaScript: getCheckboxPositions()
    for (int i = 0; i < segment; i++) {
      int x = i;
      int y = i;
      xPattern.add(Point(y, x));
    }

    for (int i = 0; i < segment; i++) {
      int x = segment - 1 - i;
      int y = segment + 1 + i;
      xPattern.add(Point(y, x));
    }

    for (int i = 0; i < segment; i++) {
      int x = (totalChannels ~/ 2) - 1 - i;
      int y = (totalChannels ~/ 2) - i;
      xPattern.add(Point(y, x));
    }

    for (int i = 0; i < segment; i++) {
      int x = segment + i;
      int y = segment - 1 - i;
      xPattern.add(Point(y, x));
    }

    return xPattern;
  }

  // Get channel information for perfect X grid position
  Map<String, dynamic> getChannelForPerfectX(
    int row,
    int col,
    int gridSize,
    int channelCount,
  ) {
    final xPoints = generateXPattern(channelCount);

    for (int i = 0; i < xPoints.length; i++) {
      if (i >= channelCount) break;

      final point = xPoints[i];
      if (point.x == row && point.y == col) {
        return {'channel': i, 'isValid': true};
      }
    }

    return {'channel': -1, 'isValid': false};
  }

  // Frame management utilities
  List<String> addFrame(
    List<String> frameData,
    String delayData,
    int animationLength,
    int channelCount,
  ) {
    final newFrameData = List<String>.from(frameData);
    final newDelayData = delayData.padRight(animationLength + 1, '4');

    newFrameData.add('0' * (channelCount * 2));

    return newFrameData;
  }

  List<String> removeFrame(
    List<String> frameData,
    String delayData,
    int index,
  ) {
    final newFrameData = List<String>.from(frameData);
    final newDelayData =
        delayData.substring(0, index) + delayData.substring(index + 1);

    newFrameData.removeAt(index);

    return newFrameData;
  }

  List<String> duplicateFrame(
    List<String> frameData,
    String delayData,
    int index,
  ) {
    final newFrameData = List<String>.from(frameData);
    final newDelayData =
        delayData.substring(0, index + 1) +
        delayData[index] +
        delayData.substring(index + 1);

    newFrameData.insert(index + 1, frameData[index]);

    return newFrameData;
  }

  String updateDelayForFrame(String delayData, int frameIndex, String delay) {
    final chars = delayData.split('');
    chars[frameIndex] = delay;
    return chars.join();
  }
}
