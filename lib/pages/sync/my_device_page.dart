import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/config_show_model.dart'; // IMPORT MODEL BARU
import 'package:iTen/services/preferences_service.dart';
import 'package:iTen/services/socket_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyDevicePage extends StatefulWidget {
  final SocketService socketService;

  const MyDevicePage({super.key, required this.socketService});

  @override
  State<MyDevicePage> createState() => _MyDevicePageState();
}

class _MyDevicePageState extends State<MyDevicePage> {
  final PreferencesService _preferencesService = PreferencesService();
  
  bool _isLoading = true;
  ConfigShowModel? _deviceConfigShow; // GUNAKAN ConfigShowModel

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
    
    // Setup socket listeners untuk config show
    _setupSocketListeners();
    
    if (widget.socketService.isConnected) {
      debugPrint("✅ Connected, requesting config show dengan XC");
      widget.socketService.requestConfigShow(); // MENGIRIM XC
    } 
    
    widget.socketService.onConnectionChanged = (isConnected) {
      if (isConnected) {
        debugPrint("✅ Connected, requesting config show dengan XC");
        widget.socketService.requestConfigShow(); // MENGIRIM XC
      } else {
        debugPrint("❌ Disconnected");
      }
    };
  }

  // TAMBAHKAN: Setup socket listeners untuk handle config2 response
  void _setupSocketListeners() {
    widget.socketService.messages.listen((message) {
      if (message.startsWith('CONFIG2_UPDATED')) {
        print('🔄 ConfigShow updated, reloading data...');
        _loadDeviceData();
      } else if (message.startsWith('config2,')) {
        print('🎯 Received config2 data directly');
        // Process config2 data langsung
        _processConfig2Data(message);
      }
    });
  }

  // TAMBAHKAN: Process config2 data langsung dari socket
  void _processConfig2Data(String message) async {
    try {
      print('🔧 Processing direct config2 data...');
      final configShow = ConfigShowModel.fromConfig2String(message);
      await _preferencesService.saveConfigShow(configShow);
      
      if (mounted) {
        setState(() {
          _deviceConfigShow = configShow;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error processing direct config2 data: $e');
    }
  }

  Future<void> _loadDeviceData() async {
    try {
      // Load dari preferences
      final configShow = await _preferencesService.getConfigShow();

      setState(() {
        _deviceConfigShow = configShow;
        _isLoading = false;
      });
      
      // Jika tidak ada data, request dari device
      if (configShow == null && widget.socketService.isConnected) {
        widget.socketService.requestConfigShow();
      }
    } catch (e) {
      print('Error loading device data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  String _generateQRCodeData() {
    if (_deviceConfigShow == null) return 'NO_CONFIG_AVAILABLE';
    return '${_deviceConfigShow!.devID},${_deviceConfigShow!.email},${_deviceConfigShow!.jumlahChannel}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.neonGreen),
          const SizedBox(height: 16),
          Text(
            'Memuat data device...',
            style: TextStyle(color: AppColors.pureWhite, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (widget.socketService.isConnected)
            Text(
              'Requesting config dari device...',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.errorRed, size: 64),
          const SizedBox(height: 16),
          Text(
            'Device config tidak ditemukan',
            style: TextStyle(
              color: AppColors.errorRed,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan device sudah terhubung dan terkonfigurasi',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (!widget.socketService.isConnected)
            Text(
              'Status: Tidak terkoneksi ke device',
              style: TextStyle(
                color: AppColors.warningYellow,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _loadDeviceData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                ),
                child: const Text('Refresh Data'),
              ),
              const SizedBox(width: 12),
              if (!widget.socketService.isConnected)
                ElevatedButton(
                  onPressed: () {
                    // Trigger reconnect dari parent
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlack,
                    foregroundColor: AppColors.neonGreen,
                    side: BorderSide(color: AppColors.neonGreen),
                  ),
                  child: const Text('Connect'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'MY DEVICE QR CODE',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan QR Code ini untuk sinkronisasi dengan device lain:',
              style: TextStyle(color: AppColors.pureWhite, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // QR Code Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonGreen.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: QrImageView(
                data: _generateQRCodeData(),
                version: QrVersions.auto,
                size: 250,
                backgroundColor: AppColors.primaryBlack,
                foregroundColor: AppColors.neonGreen,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.neonGreen,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.neonGreen,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Format: ITEN_DEVICE',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DEVICE INFORMATION',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.neonGreen),
                  ),
                  child: Text(
                    'XCC DATA',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Device ID
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Device ID',
              value: _deviceConfigShow?.devID ?? '-',
            ),
            const SizedBox(height: 16),

            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: _deviceConfigShow?.email ?? '-',
            ),
            const SizedBox(height: 16),

            // Firmware
            _buildInfoRow(
              icon: Icons.memory,
              label: 'Firmware',
              value: _deviceConfigShow?.firmware ?? '-',
            ),
            const SizedBox(height: 16),

            // Jumlah Channel
            _buildInfoRow(
              icon: Icons.tune,
              label: 'Jumlah Channel',
              value: '${_deviceConfigShow?.jumlahChannel ?? 0}',
            ),
            const SizedBox(height: 16),

            // Speed Run
            _buildInfoRow(
              icon: Icons.speed,
              label: 'Speed Run',
              value: '${_deviceConfigShow?.speedRun ?? 0} ms',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.neonGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.socketService.isConnected 
                    ? AppColors.successGreen 
                    : AppColors.errorRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.socketService.isConnected 
                        ? 'Terhubung ke Device' 
                        : 'Tidak Terhubung',
                    style: TextStyle(
                      color: widget.socketService.isConnected 
                          ? AppColors.successGreen 
                          : AppColors.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.socketService.isConnected 
                        ? 'Data berasal dari config show (XCC)' 
                        : 'Hubungkan device untuk mendapatkan data',
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.socketService.isConnected)
              ElevatedButton(
                onPressed: () {
                  // Trigger reconnect - bisa ditambahkan callback ke parent
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Connect'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: _isLoading
          ? _buildLoadingState()
          : _deviceConfigShow == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // _buildConnectionStatus(),
                      // const SizedBox(height: 16),
                      _buildQRCodeSection(),
                      const SizedBox(height: 16),
                      _buildDeviceInfoSection(),
                    ],
                  ),
                ),
    );
  }
}