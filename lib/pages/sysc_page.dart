import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/config_service.dart';
import 'package:ninexmano_matrix/services/preferences_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SyncPage extends StatefulWidget {
  final SocketService socketService;

  const SyncPage({super.key, required this.socketService});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final PreferencesService _preferencesService = PreferencesService();
  final ConfigService _configService = ConfigService();
  
  // State variables
  bool _isMasterDevice = false;
  bool _isScanning = false;
  bool _showModeActive = false;
  bool _testModeEnabled = false;
  int _speedRun = 50;
  
  List<DeviceInfo> _syncedDevices = [];
  List<String> _logMessages = [];
  
  // Controller untuk speed run
  final TextEditingController _speedController = TextEditingController();
  
  // Stream subscriptions
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializePage();
    _setupSocketListeners();
  }

  Future<void> _initializePage() async {
    await _configService.initialize();
    await _checkMasterStatus();
    _speedController.text = _speedRun.toString();
  }

  Future<void> _checkMasterStatus() async {
    final config = await _preferencesService.getDeviceConfig();
    // Logic untuk menentukan master device bisa berdasarkan:
    // - Device dengan MAC tertentu
    // - Device pertama yang di-scan
    // - Manual selection
    setState(() {
      _isMasterDevice = config?.email.isNotEmpty ?? false;
    });
  }

  void _setupSocketListeners() {
    // Listen untuk messages dari socket
    _messageSubscription = widget.socketService.messages.listen((message) {
      _handleSocketMessage(message);
    });

    // Listen untuk connection status
    _connectionSubscription = widget.socketService.connectionStatus.listen((connected) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleSocketMessage(String message) {
    print('SyncPage received: $message');
    _addLogMessage('📥: $message');

    if (message.startsWith('config2,')) {
      _handleConfigShowResponse(message);
    } else if (message.startsWith('info,')) {
      final infoMessage = message.substring(5);
      _showSnackbar(infoMessage);
      _addLogMessage('💡: $infoMessage');
    } else if (message.startsWith('CONFIG_UPDATED:')) {
      _handleConfigUpdated(message);
    }
  }

  void _handleConfigShowResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 6) {
      _addLogMessage('✅ Mode Show aktif - Firmware: ${parts[1]}');
      
      setState(() {
        _showModeActive = true;
        _speedRun = int.tryParse(parts[2]) ?? 50;
        _speedController.text = _speedRun.toString();
      });
    }
  }

  void _handleConfigUpdated(String message) {
    final deviceId = message.substring(15);
    _addLogMessage('🔄 Config updated for device: $deviceId');
    
    // Refresh master status
    _checkMasterStatus();
  }

  // ========== QR CODE & SCANNING ==========

  String _generateQRCodeData() {
    final config = _configService.currentConfig;
    if (config == null) return 'NO_CONFIG_AVAILABLE';

    // Format: MANO_SYNC|MAC|CHANNELS|EMAIL|FIRMWARE
    return 'MANO_SYNC|${config.mac}|${config.jumlahChannel}|${config.email}|${config.firmware}';
  }

  Future<void> _scanQRCode() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);
    
    try {
      final result = await BarcodeScanner.scan();
      
      if (result.type == ResultType.Barcode) {
        _processScannedQRCode(result.rawContent);
      } else {
        _showSnackbar('Scan dibatalkan atau tidak valid');
      }
    } on PlatformException catch (e) {
      _showSnackbar('Error scanning: ${e.message}');
    } catch (e) {
      _showSnackbar('Error: $e');
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _processScannedQRCode(String qrData) {
    _addLogMessage('📷 Scanned: $qrData');
    
    final parts = qrData.split('|');
    if (parts.length >= 5 && parts[0] == 'MANO_SYNC') {
      final deviceInfo = DeviceInfo(
        mac: parts[1],
        channels: int.tryParse(parts[2]) ?? 0,
        email: parts[3],
        firmware: parts[4],
        isOnline: false, // Akan diupdate via ESP-NOW
      );
      
      _addSyncedDevice(deviceInfo);
      _setupDeviceForShow(deviceInfo);
    } else {
      _showSnackbar('Format QR Code tidak valid');
    }
  }

  void _addSyncedDevice(DeviceInfo device) {
    setState(() {
      if (!_syncedDevices.any((d) => d.mac == device.mac)) {
        _syncedDevices.add(device);
        _addLogMessage('✅ Device ditambahkan: ${device.mac}');
      }
    });
  }

  // ========== MANO SHOW SETUP ==========

  void _setupDeviceForShow(DeviceInfo device) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    // Kirim command XD untuk setup device
    final command = 'XD|${_syncedDevices.length}|${_syncedDevices.length}|${device.email}|${device.mac}|${device.channels}';
    widget.socketService.send(command);
    
    _addLogMessage('🔧 Setup device: ${device.mac}');
  }

  void _enterShowMode() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    // Kirim command XC untuk masuk mode show
    widget.socketService.send('XC');
    _addLogMessage('🎭 Memasuki Mano Show Mode...');
  }

  void _startShow() {
    if (!_showModeActive) {
      _showSnackbar('Masuk ke Show Mode terlebih dahulu');
      return;
    }

    // Start dengan animasi 1 (auto)
    widget.socketService.remoteShow('A');
    _addLogMessage('▶️ Memulai show - Animasi 1');
  }

  void _stopShow() {
    widget.socketService.remoteShow('Z'); // Auto mode off
    _addLogMessage('⏹️ Menghentikan show');
  }

  void _nextAnimation() {
    if (!_showModeActive) return;
    
    // Logic untuk next animation berdasarkan stateRemoteShow di Arduino
    // Ini akan dihandle oleh Arduino secara otomatis dalam playAnimShow()
    _addLogMessage('⏭️ Next animation...');
  }

  void _toggleTestMode() {
    setState(() {
      _testModeEnabled = !_testModeEnabled;
    });
    
    widget.socketService.setTestModeShow(_testModeEnabled);
    _addLogMessage(_testModeEnabled ? '🔴 Test Mode ON' : '🟢 Test Mode OFF');
  }

  void _updateSpeedRun() {
    final speed = int.tryParse(_speedController.text) ?? 50;
    if (speed >= 10 && speed <= 1000) {
      setState(() => _speedRun = speed);
      widget.socketService.setSpeedRun(speed);
      _addLogMessage('⚡ Speed run diupdate: $speed ms');
    } else {
      _showSnackbar('Speed harus antara 10-1000 ms');
    }
  }

  // ========== REMOTE CONTROL FOR SHOW ==========

  void _controlShowAnimation(int animationNumber) {
    if (!_showModeActive) return;

    final command = String.fromCharCode(64 + animationNumber); // A=1, B=2, etc.
    widget.socketService.remoteShow(command);
    _addLogMessage('🎛️ Animasi $animationNumber');
  }

  // ========== UI BUILDERS ==========

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.socketService.isConnected 
            ? AppColors.successGreen.withOpacity(0.1)
            : AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.socketService.isConnected 
              ? AppColors.successGreen 
              : AppColors.errorRed,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.socketService.isConnected ? Icons.wifi : Icons.wifi_off,
            color: widget.socketService.isConnected 
                ? AppColors.successGreen 
                : AppColors.errorRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.socketService.isConnected 
                  ? 'Terhubung ke Device - Siap Sync'
                  : 'DISCONNECTED - Tidak bisa sync',
              style: TextStyle(
                color: widget.socketService.isConnected 
                    ? AppColors.successGreen 
                    : AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _isMasterDevice ? 'MASTER DEVICE' : 'SLAVE DEVICE',
              style: TextStyle(
                color: _isMasterDevice ? AppColors.neonGreen : AppColors.pureWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            if (_isMasterDevice) ...[
              const Text(
                'Scan QR Code ini di device lain untuk sinkronisasi:',
                style: TextStyle(color: AppColors.pureWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: QrImageView(
                  data: _generateQRCodeData(),
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: AppColors.primaryBlack,
                  foregroundColor: AppColors.neonGreen,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildActionButton(
                text: 'SCAN DEVICE LAIN',
                onPressed: _scanQRCode,
                icon: Icons.qr_code_scanner,
                isLoading: _isScanning,
              ),
            ] else ...[
              const Text(
                'Scan QR Code dari Master Device untuk bergabung:',
                style: TextStyle(color: AppColors.pureWhite),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              _buildActionButton(
                text: 'SCAN MASTER QR CODE',
                onPressed: _scanQRCode,
                icon: Icons.qr_code_scanner,
                isLoading: _isScanning,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncedDevicesList() {
    if (_syncedDevices.isEmpty) {
      return Card(
        color: AppColors.darkGrey,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Belum ada device yang tersinkronisasi',
            style: TextStyle(color: AppColors.pureWhite),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEVICE TERSINKRONISASI',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._syncedDevices.map((device) => _buildDeviceTile(device)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceTile(DeviceInfo device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            device.isOnline ? Icons.check_circle : Icons.radio_button_off,
            color: device.isOnline ? AppColors.successGreen : AppColors.errorRed,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAC: ${device.mac}',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${device.channels} Channels • ${device.firmware}',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (device.isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ONLINE',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShowControls() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MANO SHOW CONTROLS',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Status Show Mode
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showModeActive 
                    ? AppColors.successGreen.withOpacity(0.1)
                    : AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    _showModeActive ? Icons.play_arrow : Icons.stop,
                    color: _showModeActive ? AppColors.successGreen : AppColors.errorRed,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showModeActive ? 'SHOW MODE AKTIF' : 'SHOW MODE NONAKTIF',
                    style: TextStyle(
                      color: _showModeActive ? AppColors.successGreen : AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Speed Control
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _speedController,
                    decoration: InputDecoration(
                      labelText: 'Speed Run (ms)',
                      labelStyle: TextStyle(color: AppColors.pureWhite),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                    ),
                    style: TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSmallButton('UPDATE', _updateSpeedRun),
              ],
            ),
            const SizedBox(height: 16),
            
            // Control Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmallButton(
                  _showModeActive ? 'STOP SHOW' : 'START SHOW',
                  _showModeActive ? _stopShow : _enterShowMode,
                ),
                _buildSmallButton('TEST MODE', _toggleTestMode),
                if (_showModeActive) ...[
                  _buildSmallButton('ANIM 1', () => _controlShowAnimation(1)),
                  _buildSmallButton('ANIM 2', () => _controlShowAnimation(2)),
                  _buildSmallButton('ANIM 3', () => _controlShowAnimation(3)),
                  _buildSmallButton('NEXT', _nextAnimation),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'SYSTEM LOG',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSmallButton('CLEAR', () {
                  setState(() => _logMessages.clear());
                }),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              height: 150,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
              ),
              child: _logMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada log messages',
                        style: TextStyle(color: AppColors.pureWhite),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        final message = _logMessages.reversed.toList()[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: AppColors.pureWhite.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.primaryBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppColors.primaryBlack,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSmallButton(String text, VoidCallback onPressed) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.neonGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _addLogMessage(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final logMessage = '[$timestamp] $message';
    
    setState(() {
      _logMessages.add(logMessage);
      // Keep only last 50 messages
      if (_logMessages.length > 50) {
        _logMessages.removeAt(0);
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          message,
          style: TextStyle(color: AppColors.primaryBlack),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: AppBar(
        title: const Text('Sinkronisasi Device'),
        backgroundColor: AppColors.darkGrey,
        foregroundColor: AppColors.neonGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildConnectionStatus(),
            const SizedBox(height: 16),
            _buildQRCodeSection(),
            const SizedBox(height: 16),
            _buildSyncedDevicesList(),
            const SizedBox(height: 16),
            _buildShowControls(),
            const SizedBox(height: 16),
            _buildLogSection(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _speedController.dispose();
    super.dispose();
  }
}

// Model untuk device info
class DeviceInfo {
  final String mac;
  final int channels;
  final String email;
  final String firmware;
  bool isOnline;

  DeviceInfo({
    required this.mac,
    required this.channels,
    required this.email,
    required this.firmware,
    required this.isOnline,
  });
}