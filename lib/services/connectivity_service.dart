import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  
  final Connectivity _connectivity = Connectivity();
  
  ConnectivityService._internal();

  Future<bool> get isConnected async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }

  // Cek jenis koneksi
  Future<ConnectivityResult> get connectionType async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      print('❌ Error getting connection type: $e');
      return ConnectivityResult.none;
    }
  }

  // Stream untuk listen perubahan koneksi
  Stream<ConnectivityResult> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}