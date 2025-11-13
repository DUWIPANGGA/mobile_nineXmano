import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/config_service.dart';
import 'package:iTen/services/preferences_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyDevicePage extends StatefulWidget {
  const MyDevicePage({super.key});

  @override
  State<MyDevicePage> createState() => _MyDevicePageState();
}

class _MyDevicePageState extends State<MyDevicePage> {
  final PreferencesService _preferencesService = PreferencesService();
  final ConfigService _configService = ConfigService();
  
  bool _isLoading = true;
  ConfigModel? _deviceConfig;

  @override
  void initState() {
    super.initState();
    _loadDeviceData();
  }

  Future<void> _loadDeviceData() async {
    try {
      await _configService.initialize();
      final config = await _preferencesService.getDeviceConfig();
      
      setState(() {
        _deviceConfig = config;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading device data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateQRCodeData() {
    if (_deviceConfig == null) return 'NO_CONFIG_AVAILABLE';
    return '${_deviceConfig!.email},${_deviceConfig!.devID},${_deviceConfig!.jumlahChannel}';
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.neonGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat data device...',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 16,
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
          Icon(
            Icons.error_outline,
            color: AppColors.errorRed,
            size: 64,
          ),
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
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDeviceData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonGreen,
              foregroundColor: AppColors.primaryBlack,
            ),
            child: const Text('Coba Lagi'),
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
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
              ),
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
              'Format: MANO_DEVICE',
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
            Text(
              'DEVICE INFORMATION',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Device ID
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Device ID',
              value: _deviceConfig?.devID ?? '-',
            ),
            const SizedBox(height: 16),
            
            // MAC Address
            _buildInfoRow(
              icon: Icons.network_wifi,
              label: 'MAC Address',
              value: _deviceConfig?.mac ?? '-',
            ),
            const SizedBox(height: 16),
            
            // Email
            _buildInfoRow(
              icon: Icons.email,
              label: 'Email',
              value: _deviceConfig?.email ?? '-',
            ),
            const SizedBox(height: 16),
            
            // Firmware
            _buildInfoRow(
              icon: Icons.memory,
              label: 'Firmware',
              value: _deviceConfig?.firmware ?? '-',
            ),
            const SizedBox(height: 16),
            
            // Jumlah Channel
            _buildInfoRow(
              icon: Icons.tune,
              label: 'Jumlah Channel',
              value: '${_deviceConfig?.jumlahChannel ?? 0}',
            ),
            const SizedBox(height: 16),
            
            // Type License
            _buildInfoRow(
              icon: Icons.verified_user,
              label: 'Type License',
              value: '${_deviceConfig?.typeLicense ?? 0}',
            ),
            const SizedBox(height: 16),

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
        Icon(
          icon,
          color: AppColors.neonGreen,
          size: 20,
        ),
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

  Widget _buildAdvancedInfoSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADVANCED INFORMATION',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // WiFi Info
            _buildAdvancedInfoItem(
              'WiFi SSID',
              _deviceConfig?.ssid ?? '-',
            ),
            const SizedBox(height: 12),
            
            _buildAdvancedInfoItem(
              'Welcome Animation',
              '${_deviceConfig?.animWelcome ?? 0}',
            ),
            const SizedBox(height: 12),
            
            _buildAdvancedInfoItem(
              'Welcome Duration',
              '${_deviceConfig?.durasiWelcome ?? 0} detik',
            ),
            const SizedBox(height: 12),
            
            _buildAdvancedInfoItem(
              'Quick Trigger',
              '${_deviceConfig?.quickTrigger ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedInfoItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Share functionality bisa ditambahkan later
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.neonGreen,
                      content: Text(
                        'Fitur share akan datang',
                        style: TextStyle(color: AppColors.primaryBlack),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share QR Code',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loadDeviceData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlack,
                  foregroundColor: AppColors.neonGreen,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppColors.neonGreen),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text(
                  'Refresh',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
          : _deviceConfig == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildQRCodeSection(),
                      const SizedBox(height: 16),
                      _buildDeviceInfoSection(),
                      const SizedBox(height: 16),
                      _buildAdvancedInfoSection(),
                      const SizedBox(height: 16),
                      // _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }
}