import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ninexmano_matrix/services/config_service.dart';

class SocketService {
  final String host;
  final int port;
  Socket? _socket;
  bool _isConnected = false;

  final _messageController = StreamController<String>.broadcast();
  final _binaryController = StreamController<List<int>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<String> get messages => _messageController.stream;
  Stream<List<int>> get binaryData => _binaryController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  SocketService({this.host = '192.168.4.1', this.port = 11223});

  bool get isConnected => _isConnected;

  // ========== CONNECTION MANAGEMENT ==========

  Future<void> connect() async {
    try {
      print('🔄 Connecting to $host:$port ...');
      _socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      _isConnected = true;
      _connectionController.add(true);
      print('✅ Connected to server.');

      _socket!.listen(
        (data) {
          _handleIncomingData(data);
        },
        onError: (error) {
          print('❌ Socket error: $error');
          _disconnect();
        },
        onDone: () {
          print('🔌 Connection closed by server.');
          _disconnect();
        },
      );
    } catch (e) {
      print('❌ Connection failed: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void disconnect() {
    _disconnect();
  }

  void _disconnect() {
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
    print('🔌 Disconnected from server.');
  }

  // ========== INCOMING DATA HANDLER ==========

  void _handleIncomingData(List<int> data) {
    print('📥 Received ${data.length} bytes of data');

    // Coba decode sebagai UTF-8 text dulu
    try {
      final message = utf8.decode(data, allowMalformed: false).trim();
      print('🔤 Decoded as UTF-8 text: "$message"');
      _messageController.add(message);
      _handleIncomingMessage(message);
    } catch (e) {
      // Jika bukan UTF-8, handle sebagai binary data
      print('🔢 Data is binary, cannot decode as UTF-8');
      _binaryController.add(data);
      _handleBinaryData(data);
    }
  }

  // Handle binary data
  void _handleBinaryData(List<int> data) {
    print('⚡ Handling binary data:');
    print('   - Length: ${data.length} bytes');
    print('   - First 10 bytes: ${data.take(10).toList()}');
    print('   - Hex: ${_bytesToHex(data.take(20).toList())}');

    // Coba extract text dari binary data
    _tryExtractTextFromBinary(data);
  }

  // Coba extract text dari binary data
  void _tryExtractTextFromBinary(List<int> data) {
    final textPatterns = [
      'config,',
      'config2,',
      'info,',
      'error,',
      'OK',
      'READY',
    ];

    for (final pattern in textPatterns) {
      final patternBytes = utf8.encode(pattern);
      final index = _findPatternInData(data, patternBytes);
      if (index != -1) {
        print('🎯 Found text pattern "$pattern" at index $index');

        // Coba extract text dari posisi tersebut
        try {
          final extracted = utf8.decode(
            data.sublist(index),
            allowMalformed: true,
          );
          final lines = extracted.split('\n').where((line) => line.isNotEmpty);
          for (final line in lines) {
            if (line.isNotEmpty) {
              print('📜 Extracted text: "$line"');
              _messageController.add(line);
              _handleIncomingMessage(line);
            }
          }
        } catch (e) {
          print('⚠️ Could not extract text from binary: $e');
        }
        break;
      }
    }
  }

  // Cari pattern dalam binary data
  int _findPatternInData(List<int> data, List<int> pattern) {
    for (int i = 0; i <= data.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  // Convert bytes to hex string
  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(' ');
  }

  // ========== INCOMING MESSAGE HANDLER ==========

  void _handleIncomingMessage(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final cleanMessage = message.trim();

    print('╔═══════════════════════════════════════════════════');
    print('║ 📥 INCOMING MESSAGE [${timestamp.split('T')[1].split('.')[0]}]');
    print('║ Raw: "$cleanMessage"');
    print('║ Length: ${cleanMessage.length} characters');
    print('╠═══════════════════════════════════════════════════');

    if (cleanMessage.startsWith('config,')) {
      print('║ 🔧 TYPE: CONFIG DATA');
      _handleConfigResponse(cleanMessage);
    } else if (cleanMessage.startsWith('config2,')) {
      print('║ 🎭 TYPE: CONFIG SHOW DATA');
      _handleConfigShowResponse(cleanMessage);
    } else if (cleanMessage.startsWith('info,')) {
      print('║ 💡 TYPE: INFO MESSAGE');
      _handleInfoMessage(cleanMessage);
    } else if (cleanMessage.startsWith('error,')) {
      print('║ 🚨 TYPE: ERROR MESSAGE');
      _handleErrorMessage(cleanMessage);
    } else if (cleanMessage == 'OK') {
      print('║ ✅ TYPE: SUCCESS RESPONSE');
      _handleOkResponse(cleanMessage);
    } else if (cleanMessage == 'READY') {
      print('║ 🟢 TYPE: READY RESPONSE');
      _handleReadyResponse(cleanMessage);
    } else if (RegExp(r'^[A-Z]{2}$').hasMatch(cleanMessage)) {
      print('║ 🔘 TYPE: REMOTE RESPONSE');
      print('║ Possible remote command response: $cleanMessage');
    } else if (RegExp(r'^\d+$').hasMatch(cleanMessage)) {
      print('║ 🔢 TYPE: NUMERIC RESPONSE');
      print('║ Value: $cleanMessage');
    } else {
      print('║ ❓ TYPE: UNKNOWN FORMAT');
      _handleUnknownMessage(cleanMessage);
    }

    print('╚═══════════════════════════════════════════════════');
  }

  // Di SocketService - Perbaikan _handleConfigResponse
  void _handleConfigResponse(String message) {
    print('🔧 Processing config data from device...');

    try {
      // Validasi message
      if (message.isEmpty || !message.startsWith('config,')) {
        print('❌ Invalid config message format');
        return;
      }
      if (message.startsWith('config,')) {
        _processConfigData(message);
      }
      if (message.startsWith('info,')) {
        _processConfigData(message);
        print(message.substring(6, message.length));
      }
      print('📨 Raw config data received: ${message.length} characters');
      print(
        '   First 100 chars: ${message.substring(0, message.length < 100 ? message.length : 100)}...',
      );

      // Process config data
    } catch (e) {
      print('❌ Error in _handleConfigResponse: $e');
      print('   Stack trace: ${e.toString()}');
    }
  }

  // Pisahkan logic processing ke method terpisah
  void _processConfigData(String message) async {
    try {
      final configService = ConfigService();
      final config = await configService.parseAndSaveConfig(message);

      if (config != null) {
        print('✅ Config processed and saved to preferences successfully');

        // Print config details
        print('📋 Saved Config Details:');
        print('   - Firmware: ${config.firmware}');
        print('   - MAC: ${config.mac}');
        print('   - Channels: ${config.jumlahChannel}');
        print('   - Email: ${config.email}');
        print('   - Device ID: ${config.devID}');
        print('   - Valid: ${config.isValid}');

        // Kirim event bahwa config telah diperbarui
        _messageController.add('CONFIG_UPDATED:${config.devID}');
      } else {
        print('⚠️ Failed to process and save config data');
        _messageController.add('CONFIG_ERROR:Failed to save config');
      }
    } catch (e) {
      print('❌ Error processing config data: $e');
      _messageController.add('CONFIG_ERROR:$e');
    }
  }

  void _handleConfigShowResponse(String message) {
    final parts = message.split(',');
    print('║ 📊 Config2 Analysis:');
    print('║   - Total parts: ${parts.length}');

    if (parts.length >= 6) {
      final configData = {
        'firmware': parts[1],
        'speedRun': parts[2],
        'jumlahChannel': parts[3],
        'email': parts[4],
        'mac': parts[5],
      };
      print('║   ✅ Config2 parsed successfully');
      print('║   🎭 Data: $configData');
    } else {
      print('║   ⚠️ Incomplete config2 data');
    }
  }

  void _handleInfoMessage(String message) {
    final info = message.substring(5);
    print('║ 💬 Info: "$info"');
  }

  void _handleErrorMessage(String message) {
    final error = message.substring(6);
    print('║ 🚨 Error: "$error"');
  }

  void _handleOkResponse(String message) {
    print('║ ✅ Operation completed successfully');
  }

  void _handleReadyResponse(String message) {
    print('║ 🟢 Device is ready for commands');
  }

  void _handleUnknownMessage(String message) {
    print('║ 🔍 Unknown message analysis:');
    print('║   - Contains commas: ${message.contains(',')}');
    print('║   - Is numeric: ${RegExp(r'^\d+$').hasMatch(message)}');
    print('║   - Is alphabetic: ${RegExp(r'^[A-Za-z]+$').hasMatch(message)}');

    if (message.contains(',')) {
      final parts = message.split(',');
      print('║   - Parts breakdown:');
      for (int i = 0; i < parts.length; i++) {
        print('║     [${i + 1}] "${parts[i]}" (${parts[i].length} chars)');
      }
    }
  }

  // ========== OUTGOING MESSAGES - REMOTE CONTROL ==========

  /// Remote Control - Tombol A-D
  void remoteA() => send('RA');
  void remoteB() => send('RB');
  void remoteC() => send('RC');
  void remoteD() => send('RD');

  /// Auto Mode
  void autoABCD() => send('RE');
  void autoAllBuiltin() => send('RG');
  void turnOff() => send('RF');

  /// Builtin Animations (3-31)
  void builtinAnimation(int number) {
    if (number >= 3 && number <= 31) {
      send('RH${number.toString().padLeft(2, '0')}');
    }
  }

  // ========== OUTGOING MESSAGES - CONFIGURATION ==========

  /// Request config device
  void requestConfig() => send('CC');

  /// Set email
  void setEmail(String email) => send('CA$email');

  /// Set jumlah channel (2 digit)
  void setChannel(int channel) =>
      send('CB${channel.toString().padLeft(2, '0')}');

  /// Set delays (masing-masing 3 digit)
  void setDelays(int delay1, int delay2, int delay3, int delay4) {
    send('CD${_pad3(delay1)}${_pad3(delay2)}${_pad3(delay3)}${_pad3(delay4)}');
  }

  /// Set WiFi config
  void setWifi(String ssid, String password) {
    send('CW${_pad2(ssid.length)}${_pad2(password.length)}$ssid$password');
  }

  // ========== OUTGOING MESSAGES - ANIMATION DATA ==========

  /// Upload animasi data
  void uploadAnimation({
    required int remoteIndex, // 1-4
    required String channel, // A-J
    required int frameIndex, // 5 digit
    required String hexData, // data dalam hex
  }) {
    final dataLength = hexData.length ~/ 2;
    send(
      'M$remoteIndex$channel${_pad5(frameIndex)}${_pad4(dataLength)}$hexData',
    );
  }

  /// Upload delay data
  void uploadDelay({
    required int remoteIndex, // 1-4
    required String delayType, // K/M/N
    required int frameIndex, // 5 digit
    required String delayData,
  }) {
    send(
      'M$remoteIndex$delayType${_pad5(frameIndex)}${_pad3(delayData.length)}$delayData',
    );
  }

  // ========== OUTGOING MESSAGES - BUILTIN ANIMATIONS ==========

  /// Set builtin animation untuk remote tertentu
  void setBuiltinAnimation(int remoteIndex, int animNumber) {
    send('B$remoteIndex${animNumber.toString().padLeft(2, '0')}');
  }

  // ========== OUTGOING MESSAGES - LICENSE ==========

  /// Aktivasi lisensi
  void activateLicense(String serialNumber) {
    send('LA${_pad4(serialNumber.length)}$serialNumber');
  }

  // ========== OUTGOING MESSAGES - CALIBRATION ==========

  /// Enable/disable kalibrasi mode
  void setCalibrationMode(bool enable) => send('KM${enable ? 1 : 0}');

  /// Set kalibrasi remote
  void setCalibration(int remoteNum, int buttonID) =>
      send('KR$remoteNum$buttonID');

  // ========== OUTGOING MESSAGES - TRIGGER SETTINGS ==========

  /// Set trigger data
  void setTrigger(int triggerNum, List<int> data) {
    final csvData = data.map((e) => e.toString()).join(',');
    send('S$triggerNum${_pad3(csvData.length)}$csvData');
  }

  /// Set trigger mode
  void setTriggerLow(int value) => send('SL$value');
  void setTriggerHigh(int value) => send('SH$value');
  void setTriggerFog(int value) => send('SF$value');
  void setQuickTrigger(int value) => send('SQ$value');
// Di SocketService class - tambahkan method ini

/// Kirim trigger toggle (0 atau 1)
void sendTriggerToggle(String triggerCode, bool isActive) {
  final value = isActive ? 1 : 0;
  send('$triggerCode$value');
  print('🔘 Trigger Toggle: $triggerCode$value');
}

/// Kirim mapping data (10 frame + 1 channel)
void sendMappingData(String mappingCode, List<int> frameData, int channel) {
  // Validasi frame data harus 10 elements
  final paddedFrameData = List<int>.from(frameData);
  
  // Pad dengan 0 jika kurang dari 10 frame
  while (paddedFrameData.length < 10) {
    paddedFrameData.add(0);
  }
  
  // Pastikan tidak lebih dari 10 frame
  if (paddedFrameData.length > 10) {
    paddedFrameData.removeRange(10, paddedFrameData.length);
  }
  
  // Format: [code][frame1],[frame2],...,[frame10],[channel]
  final frameString = paddedFrameData.take(10).join(',');
  final data = '$frameString,$channel';
  
  send('$mappingCode$data');
  print('🗺️ Mapping Data: $mappingCode$data');
  print('   - Frames: ${paddedFrameData.length} (padded to 10)');
  print('   - Channel: $channel');
}

/// Kirim mapping data dengan List<int> untuk frames
void sendMappingDataWithList(String mappingCode, List<int> frames, int channel) {
  sendMappingData(mappingCode, frames, channel);
}
  // ========== OUTGOING MESSAGES - WELCOME ANIMATION ==========

  /// Set welcome animation
  void setWelcomeAnimation(int animNumber, int duration) {
    send('W${_pad3(animNumber)}${_pad3(duration)}');
  }

  // ========== OUTGOING MESSAGES - MITRA ID ==========

  /// Set mitra ID
  void setMitraID(String mitraID) {
    send('Y${_pad3(mitraID.length)}$mitraID');
  }

  // ========== OUTGOING MESSAGES - RESET ==========

  /// Reset device ke factory default
  void resetDevice() => send('Z');

  // ========== OUTGOING MESSAGES - MANO SHOW MODE ==========

  /// Request config show
  void requestConfigShow() => send('XC');

  /// Remote control show mode
  void remoteShow(String command) => send('XR$command');

  /// Setup device show
  void setupDeviceShow(
    int jumlahDevice,
    int index,
    String email,
    String mac,
    int jumlahChannel,
  ) {
    send('XD$jumlahDevice,$index,$email,$mac,$jumlahChannel');
  }

  /// Test mode show
  void setTestModeShow(bool enable) => send('XM${enable ? 1 : 0}');

  /// Set speed run show
  void setSpeedRun(int speed) => send('XS${_pad3(speed)}');

  // ========== UTILITY METHODS ==========

  String _pad2(int number) => number.toString().padLeft(2, '0');
  String _pad3(int number) => number.toString().padLeft(3, '0');
  String _pad4(int number) => number.toString().padLeft(4, '0');
  String _pad5(int number) => number.toString().padLeft(5, '0');

  /// Generic send method - PUBLIC
  void send(String message) {
    if (_isConnected && _socket != null) {
      _socket!.write('$message\n');
      print('📤 Sent: $message');
    } else {
      print('❌ Cannot send, not connected.');
    }
  }

  /// Private send method untuk internal use
  void _send(String message) {
    send(message);
  }

  void dispose() {
    _disconnect();
    _messageController.close();
    _binaryController.close();
    _connectionController.close();
  }
}
