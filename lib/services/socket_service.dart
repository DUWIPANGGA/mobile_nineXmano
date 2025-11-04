import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SocketService {
  final String host;
  final int port;
  Socket? _socket;
  bool _isConnected = false;

  final _messageController = StreamController<String>.broadcast();

  Stream<String> get messages => _messageController.stream;

 SocketService({
    this.host = '192.168.4.1',
    this.port = 8080,
  });
  bool get isConnected => _isConnected;

  /// 🔌 Connect ke server
  Future<void> connect() async {
    try {
      print('Connecting to $host:$port ...');
      _socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      _isConnected = true;
      print('Connected to server.');

      _socket!.listen(
        (data) {
          final message = utf8.decode(data);
          _messageController.add(message);
          print('Received: $message');
        },
        onError: (error) {
          print('Socket error: $error');
          disconnect();
        },
        onDone: () {
          print('Connection closed by server.');
          disconnect();
        },
      );
    } catch (e) {
      print('Connection failed: $e');
      _isConnected = false;
    }
  }

  /// ✉️ Kirim data ke server
  void send(String message) {
    if (_isConnected && _socket != null) {
      _socket!.write('$message\n');
      print('Sent: $message');
    } else {
      print('Cannot send, not connected.');
    }
  }

  /// ❌ Putuskan koneksi
  void disconnect() {
    _socket?.destroy();
    _socket = null;
    _isConnected = false;
    print('Disconnected from server.');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
