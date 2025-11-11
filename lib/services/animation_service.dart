// services/animation_service.dart
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/services/preferences_service.dart';

class AnimationService {
  final PreferencesService _prefsService = PreferencesService();

  Future<void> initialize() async {
    await _prefsService.initialize();
  }

  // Animation data conversion and validation
  List<String> createGNMFrameData(
    List<String> frameData,
    int animationLength,
    int channelCount,
  ) {
    List<String> formattedFrameData = [];

    for (int i = 0; i < animationLength; i++) {
      String twoDigitHex = _convertTo2DigitHex(frameData[i]);
      String formattedFrame = twoDigitHex.padRight(12, '0');
      formattedFrameData.add(formattedFrame);
    }

    // Add padding until total 10 data frames
    int currentFrames = animationLength;

    for (int i = currentFrames; i < frameData.length; i++) {
      formattedFrameData.add("0" * (frameData.length * 2));
    }
    print(formattedFrameData);
    return formattedFrameData;
  }

  // Convert frame to decimal format (EXACT match JavaScript convertToDecimal function)
  String convertToDecimal(List<bool> frame, int channelCount) {
    String decimalString = '';

    for (int i = 0; i < channelCount; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; j++) {
        int ledIndex = i + j;
        if (ledIndex < channelCount && frame[ledIndex]) {
          byte |= (1 << (7 - j)); // Sama persis dengan JavaScript
        }
      }
      // Format: tiga digit decimal + koma (sama seperti JavaScript)
      decimalString += byte.toString().padLeft(3, '0') + ',';
    }

    // Remove last comma (sama seperti JavaScript: slice(0, -1))
    if (decimalString.isNotEmpty && decimalString.endsWith(',')) {
      decimalString = decimalString.substring(0, decimalString.length - 1);
    }

    return decimalString;
  }

  String _convertTo2DigitHex(String frameHex) {
    int sum = 0;

    for (int i = 0; i < frameHex.length; i += 2) {
      if (i + 2 <= frameHex.length) {
        final byteHex = frameHex.substring(i, i + 2);
        final byteValue = int.parse(byteHex, radix: 16);
        sum = (sum + byteValue) % 256;
      }
    }

    return sum.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  // Frame data structure management
  List<String> updateFrameDataStructure(
    List<String> frameData,
    int channelCount,
  ) {
    final hexLength = channelCount * 2;

    return frameData.map((frame) {
      if (frame.length > hexLength) {
        return frame.substring(0, hexLength);
      } else if (frame.length < hexLength) {
        return frame.padRight(hexLength, '0');
      }
      return frame;
    }).toList();
  }

  // LED operations
  String toggleLED(String frame, int channel, int channelCount) {
    final ledIndex = channel ~/ 4;
    final bitPosition = (channel % 4) * 2;

    print('=== TOGGLE LED DEBUG ===');
    print('Channel: $channel (0-based) / ${channel + 1} (1-based)');
    print('LED Index: $ledIndex');
    print('Bit Position: $bitPosition');
    print('Original Frame: $frame');

    if (ledIndex < frame.length ~/ 2) {
      final hexDigitIndex = ledIndex;
      final hexValue = int.parse(
        frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2),
        radix: 16,
      );

      print('Byte Index: $hexDigitIndex');
      print(
        'Byte Hex: ${frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2)}',
      );
      print('Byte Decimal: $hexValue');
      print('Byte Binary: ${hexValue.toRadixString(2).padLeft(8, '0')}');

      // Debug: Tampilkan status LED sebelum toggle
      print('\n--- BEFORE TOGGLE ---');
      // _debugLEDStatusCompact(frame, channelCount);

      final mask = 0x03 << bitPosition;
      final newHexValue = hexValue ^ mask;
      final newHexString = newHexValue.toRadixString(16).padLeft(2, '0');

      // print(
      //   'Mask: 0x${mask.toRadixString(16).padLeft(2, '0')} (binary: ${mask.toRadixString(2).padLeft(8, '0')})',
      // );
      // print('New Byte Value: $newHexValue (0x$newHexString)');
      // print('New Byte Binary: ${newHexValue.toRadixString(2).padLeft(8, '0')}');

      final newFrame =
          frame.substring(0, hexDigitIndex * 2) +
          newHexString +
          frame.substring(hexDigitIndex * 2 + 2);

      // print('\n--- AFTER TOGGLE ---');
      // _debugLEDStatusCompact(newFrame, channelCount);

      // Tampilkan hex representation untuk 8 channel per byte
      // print('\n--- 8-CHANNEL HEX REPRESENTATION ---');
      frameToHex(newFrame, channelCount);

      print('=====================\n');
      print("new fram is $newFrame");
      return newFrame;
    }

    print('ERROR: LED index out of range!');
    print('=====================\n');
    return frame;
  }

  // Helper method untuk debug status semua LED (format compact 8 channel per baris)
  void _debugLEDStatusCompact(String frame, int channelCount) {
    print('LED Status (8 channels per row):');
    for (int startChannel = 0; startChannel < channelCount; startChannel += 8) {
      String row = '';
      for (
        int channel = startChannel;
        channel < startChannel + 8 && channel < channelCount;
        channel++
      ) {
        final ledIndex = channel ~/ 4;
        final bitPosition = (channel % 4) * 2;

        if (ledIndex < frame.length ~/ 2) {
          final hexDigitIndex = ledIndex;
          final hexValue = int.parse(
            frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2),
            radix: 16,
          );

          final isOn = (hexValue >> bitPosition) & 0x03 != 0;
          final bitValue = (hexValue >> bitPosition) & 0x03;

          // Format: Channel[status](bits)
          final status = isOn ? 'ON' : 'OFF';
          final marker = channel == channel ? ' <--' : '';
          row +=
              'Ch${(channel + 1).toString().padLeft(2)}[$status](${bitValue.toRadixString(2).padLeft(2, '0')})$marker ';
        } else {
          row += 'Ch${(channel + 1).toString().padLeft(2)}[---] ';
        }
      }
      print('  $row');
    }
  }

  List frameToHex(String frame, int channelCount) {
    List<String> frameHex = [];

    for (int byteIndex = 0; byteIndex < frame.length ~/ 2; byteIndex++) {
      final startChannel = byteIndex * 8; // 8 channel per byte
      final endChannel = startChannel + 7;

      if (startChannel >= channelCount) break;

      final actualEndChannel = endChannel < channelCount
          ? endChannel
          : channelCount - 1;
      final byteHex = frame.substring(byteIndex * 2, byteIndex * 2 + 2);

      // Hitung nilai byte dari 8 channel
      int byteValue = 0;
      for (int i = 0; i < 8; i++) {
        int channel = startChannel + i;
        if (channel < channelCount) {
          final ledIndex = channel ~/ 4;
          final bitPosition = (channel % 4) * 2;

          if (ledIndex < frame.length ~/ 2) {
            final hexDigitIndex = ledIndex;
            final hexVal = int.parse(
              frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2),
              radix: 16,
            );
            final isOn = (hexVal >> bitPosition) & 0x03 != 0;
            if (isOn) {
              byteValue |= (1 << (7 - i)); // Set bit sesuai posisi
            }
          }
        }
      }

      final calculatedHex = byteValue
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      print(
        '  Ch${(startChannel + 1).toString().padLeft(2)}-${(actualEndChannel + 1).toString().padLeft(2)}: 0x$calculatedHex (${byteValue.toRadixString(2).padLeft(8, '0')})',
      );
      frameHex.add(calculatedHex);
    }

    // Tampilkan full hex string
    print('  Full Hex Frames: ${frameHex.toString()}');
    return frameHex;
  }

  // Helper method untuk menampilkan 8 channel per byte hex
  // void _debug8ChannelHexRepresentation(String frame, int channelCount) {
  //   print('8-Channel Hex Representation:');

  //   for (int byteIndex = 0; byteIndex < frame.length ~/ 2; byteIndex++) {
  //     final startChannel = byteIndex * 8; // 8 channel per byte
  //     final endChannel = startChannel + 7;

  //     if (startChannel >= channelCount) break;

  //     final actualEndChannel = endChannel < channelCount
  //         ? endChannel
  //         : channelCount - 1;
  //     final byteHex = frame.substring(byteIndex * 2, byteIndex * 2 + 2);

  //     // Hitung nilai byte dari 8 channel
  //     int byteValue = 0;
  //     for (int i = 0; i < 8; i++) {
  //       int channel = startChannel + i;
  //       if (channel < channelCount) {
  //         final ledIndex = channel ~/ 4;
  //         final bitPosition = (channel % 4) * 2;

  //         if (ledIndex < frame.length ~/ 2) {
  //           final hexDigitIndex = ledIndex;
  //           final hexVal = int.parse(
  //             frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2),
  //             radix: 16,
  //           );
  //           final isOn = (hexVal >> bitPosition) & 0x03 != 0;
  //           if (isOn) {
  //             byteValue |= (1 << (7 - i)); // Set bit sesuai posisi
  //           }
  //         }
  //       }
  //     }

  //     final calculatedHex = byteValue
  //         .toRadixString(16)
  //         .padLeft(2, '0')
  //         .toUpperCase();
  //     print(
  //       '  Ch${(startChannel + 1).toString().padLeft(2)}-${(actualEndChannel + 1).toString().padLeft(2)}: 0x$calculatedHex (${byteValue.toRadixString(2).padLeft(8, '0')})',
  //     );
  //   }

  //   // Tampilkan full hex string
  //   print('  Full Hex Frame: $frame');
  // }

  bool isLEDOn(String frame, int channel, int channelCount) {
    final ledIndex = channel ~/ 4;
    final bitPosition = (channel % 4) * 2;

    if (ledIndex < frame.length ~/ 2) {
      final hexDigitIndex = ledIndex;
      final hexValue = int.parse(
        frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2),
        radix: 16,
      );
      return (hexValue >> bitPosition) & 0x03 != 0;
    }

    return false;
  }

  // Selected animations management
  Future<void> saveToSelectedAnimations(
    String key,
    AnimationModel animation,
  ) async {
    await _prefsService.initialize();

    final selectedAnimations = _prefsService.getSelectedAnimations();
    final animationMap = animation.toMap();

    animationMap['selected_key'] = key;
    animationMap['saved_at'] = DateTime.now().toIso8601String();

    final existingIndex = selectedAnimations.indexWhere(
      (item) => item['selected_key'] == key,
    );

    List<Map<String, dynamic>> newList;
    if (existingIndex != -1) {
      newList = List.from(selectedAnimations);
      newList[existingIndex] = animationMap;
    } else {
      newList = [...selectedAnimations, animationMap];
    }

    await _prefsService.saveSelectedAnimations(newList);
  }

  String generateAnimationKey(
    String animationName,
    int channelCount,
    String email,
  ) {
    final channelStr = channelCount.toString().padLeft(3, '0');
    final username = email.split('@').first;
    return '$channelStr $animationName $username';
  }

  // User preferences
  Future<int> getLastSelectedChannel() async {
    await _prefsService.initialize();
    return _prefsService.getLastSelectedChannel();
  }

  Future<void> saveLastSelectedChannel(int channelCount) async {
    await _prefsService.initialize();
    _prefsService.saveLastSelectedChannel(channelCount);
  }

  void addUserSelectedAnimation(AnimationModel animation) {
    _prefsService.addUserSelectedAnimation(animation);
  }
}
