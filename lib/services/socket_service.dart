import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SocketService {
  final String host;
  final int port;
  Socket? _socket;
  bool _isConnected = false;

  final _messageController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<String> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionController.stream;

  SocketService({
    this.host = '192.168.4.1',
    this.port = 11223,
  });
  
  bool get isConnected => _isConnected;

  // ========== CONNECTION MANAGEMENT ==========

  Future<void> connect() async {
    try {
      print('🔄 Connecting to $host:$port ...');
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _isConnected = true;
      _connectionController.add(true);
      print('✅ Connected to server.');

      _socket!.listen(
        (data) {
          final message = utf8.decode(data).trim();
          _messageController.add(message);
          print('📥 Received: $message');
          _handleIncomingMessage(message);
        },
        onError: (error) {
          print('❌ Socket error: $error');
          disconnect();
        },
        onDone: () {
          print('🔌 Connection closed by server.');
          disconnect();
        },
      );
    } catch (e) {
      print('❌ Connection failed: $e');
      _isConnected = false;
      _connectionController.add(false);
    }
  }

  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
    print('🔌 Disconnected from server.');
  }

  // ========== INCOMING MESSAGE HANDLER ==========

  void _handleIncomingMessage(String message) {
    if (message.startsWith('config,')) {
      _handleConfigResponse(message);
    } else if (message.startsWith('config2,')) {
      _handleConfigShowResponse(message);
    } else if (message.startsWith('info,')) {
      _handleInfoMessage(message);
    } else if (message.startsWith('error,')) {
      _handleErrorMessage(message);
    }
  }

  void _handleConfigResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 20) {
      // Parse config data
      final configData = {
        'firmware': parts[1],
        'mac': parts[2],
        'typeLicense': parts[3],
        'jumlahChannel': parts[4],
        'email': parts[5],
        'ssid': parts[6],
        'password': parts[7],
        'delay1': parts[8],
        'delay2': parts[9],
        'delay3': parts[10],
        'delay4': parts[11],
        'selection1': parts[12],
        'selection2': parts[13],
        'selection3': parts[14],
        'selection4': parts[15],
        'devID': parts[16],
        'mitraID': parts[17],
        'animWelcome': parts[18],
        'durasiWelcome': parts[19],
      };
      print('📋 Config received: $configData');
    }
  }

  void _handleConfigShowResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 6) {
      final configData = {
        'firmware': parts[1],
        'speedRun': parts[2],
        'jumlahChannel': parts[3],
        'email': parts[4],
        'mac': parts[5],
      };
      print('🎭 Show Config received: $configData');
    }
  }

  void _handleInfoMessage(String message) {
    final info = message.substring(5);
    print('💡 Info: $info');
    // Bisa ditambahkan StreamController khusus untuk info messages
  }

  void _handleErrorMessage(String message) {
    final error = message.substring(6);
    print('🚨 Error: $error');
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
  void setChannel(int channel) => send('CB${channel.toString().padLeft(2, '0')}');
  
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
    send('M$remoteIndex$channel${_pad5(frameIndex)}${_pad4(dataLength)}$hexData');
  }

  /// Upload delay data
  void uploadDelay({
    required int remoteIndex, // 1-4
    required String delayType, // K/M/N
    required int frameIndex, // 5 digit
    required String delayData,
  }) {
    send('M$remoteIndex$delayType${_pad5(frameIndex)}${_pad3(delayData.length)}$delayData');
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
  void setCalibration(int remoteNum, int buttonID) => send('KR$remoteNum$buttonID');

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
  void setupDeviceShow(int jumlahDevice, int index, String email, String mac, int jumlahChannel) {
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

  /// Generic send method
  void send(String message) {
    if (_isConnected && _socket != null) {
      _socket!.write('$message\n');
      print('📤 Sent: $message');
    } else {
      print('❌ Cannot send, not connected.');
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _connectionController.close();
  }
}