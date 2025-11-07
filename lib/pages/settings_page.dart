import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class SettingsPage extends StatefulWidget {
  final SocketService socketService;
  
  const SettingsPage({
    super.key,
    required this.socketService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _welcomeModeEnabled = true;
  String _selectedSpeed = 'SEDANG';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serialController = TextEditingController();
  final TextEditingController _activationController = TextEditingController();
  final TextEditingController _mitraIdController = TextEditingController();

  // Data dari device (akan diupdate via socket)
  String _firmwareVersion = '-';
  String _deviceId = '';
  String _licenseLevel = '';
  String _deviceChannel = '';
  String _currentEmail = '';
  String _currentSSID = '';
  String _currentPassword = '';

  final List<String> _speedOptions = ['LAMBAT', 'SEDANG', 'CEPAT', 'CEPAAT'];
  final Map<String, int> _speedValues = {
    'LAMBAT': 500,
    'SEDANG': 200,
    'CEPAT': 100,
    'CEPAAT': 50,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
    _setupSocketListeners();
    
    // Request config data saat page dibuka
    if (widget.socketService.isConnected) {
      widget.socketService.requestConfig();
    }
  }

  void _initializeData() {
    // Default values
    _emailController.text = 'example@gmail.com';
    _ssidController.text = 'MaNo';
    _passwordController.text = '11223344';
    _serialController.text = 'Serial Number Kamu';
    _activationController.text = 'Kode Aktivasi';
    _mitraIdController.text = '';
  }

  void _setupSocketListeners() {
    widget.socketService.messages.listen((message) {
      _handleSocketMessage(message);
    });
  }

  void _handleSocketMessage(String message) {
    print('SettingsPage received: $message');
    
    if (message.startsWith('config,')) {
      _handleConfigResponse(message);
    } else if (message.startsWith('info,')) {
      final infoMessage = message.substring(5);
      _showSnackbar(infoMessage);
    }
  }

  void _handleConfigResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 20) {
      setState(() {
        _firmwareVersion = parts[1];
        _deviceId = parts[16];
        _licenseLevel = parts[3];
        _deviceChannel = parts[4];
        _currentEmail = parts[5];
        _currentSSID = parts[6];
        _currentPassword = parts[7];
        
        // Update controllers dengan data aktual
        _emailController.text = _currentEmail;
        _ssidController.text = _currentSSID;
        _passwordController.text = _currentPassword;
      });
    }
  }

  // ========== SOCKET ACTIONS ==========

  void _updateEmail() {
    if (_emailController.text.isNotEmpty) {
      widget.socketService.setEmail(_emailController.text);
      _showSnackbar('Mengirim email: ${_emailController.text}');
    }
  }

  void _updateWelcomeSettings() {
    final speedValue = _speedValues[_selectedSpeed] ?? 200;
    // Kirim welcome animation settings
    widget.socketService.setWelcomeAnimation(
      _welcomeModeEnabled ? 1 : 0, 
      _welcomeModeEnabled ? 3 : 0
    );
    _showSnackbar('Welcome mode: ${_welcomeModeEnabled ? "Aktif" : "Nonaktif"} - Speed: $speedValue ms');
  }

  void _updateChannel() {
    if (_deviceChannel.isNotEmpty) {
      final channel = int.tryParse(_deviceChannel) ?? 8;
      widget.socketService.setChannel(channel);
      _showSnackbar('Channel diubah ke: $channel');
    }
  }

  void _updateWiFi() {
    if (_ssidController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      widget.socketService.setWifi(_ssidController.text, _passwordController.text);
      _showSnackbar('WiFi config dikirim - Restarting device...');
    }
  }

  void _startCalibration() {
    widget.socketService.setCalibrationMode(true);
    _showSnackbar('Mode kalibrasi diaktifkan - Silakan tekan tombol remote');
  }

  void _activateLicense() {
    if (_activationController.text.isNotEmpty) {
      widget.socketService.activateLicense(_activationController.text);
      _showSnackbar('Mengaktifkan lisensi...');
    }
  }

  void _updateMitraID() {
    if (_mitraIdController.text.isNotEmpty) {
      widget.socketService.setMitraID(_mitraIdController.text);
      _showSnackbar('Mitra ID diupdate: ${_mitraIdController.text}');
    }
  }

  void _resetFactory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'Reset Pabrik?',
          style: TextStyle(color: AppColors.neonGreen),
        ),
        content: const Text(
          'Semua settings akan dikembalikan ke default. Device akan restart.',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('BATAL', style: TextStyle(color: AppColors.pureWhite)),
          ),
          ElevatedButton(
            onPressed: () {
              widget.socketService.resetDevice();
              Navigator.pop(context);
              _showSnackbar('Reset pabrik dilakukan - Device restarting...');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: const Text('RESET', style: TextStyle(color: AppColors.pureWhite)),
          ),
        ],
      ),
    );
  }

  void _checkUpdate() {
    _showSnackbar('Checking for firmware updates...');
    // Bisa ditambahkan logic untuk check update
  }

  void _uploadFirmware() {
    _showSnackbar('Membuka firmware upload...');
    // Bisa navigate ke firmware upload page
  }

  void _contactSupport() {
    _showSnackbar('Membuka kontak support...');
    // Buka email/link support
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            _buildConnectionStatus(),
            const SizedBox(height: 16),

            // Email Section
            _buildSection(
              title: 'Email',
              children: [
                _buildTextField(
                  controller: _emailController,
                  hintText: 'example@gmail.com',
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: _updateEmail,
                  enabled: widget.socketService.isConnected,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Welcome Mode Section
            _buildSection(
              title: 'Welcome mode',
              children: [
                _buildSettingSwitch(
                  title: 'Animasi',
                  value: _welcomeModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _welcomeModeEnabled = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildSettingRow(
                  title: 'Durasi',
                  child: _buildSpeedSelector(),
                ),
                const SizedBox(height: 16),
                _buildSettingRow(
                  title: 'MaNo 06 || Balin.',
                  child: Row(
                    children: [
                      _buildCheckbox(true),
                      const SizedBox(width: 16),
                      _buildCheckbox(false),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  text: 'KIRIM',
                  onPressed: _updateWelcomeSettings,
                  enabled: widget.socketService.isConnected,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Firmware Info Section
            _buildSection(
              title: 'Versi Firmware : $_firmwareVersion',
              children: [
                _buildInfoRow('Versi Aplikasi', '1.0.6'),
                _buildInfoRow('Device ID', _deviceId),
                _buildInfoRow('Level Lisensi', _licenseLevel),
                _buildInfoRow('Device Channel', _deviceChannel),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: _updateChannel,
                  enabled: widget.socketService.isConnected,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // DEARY Speed Section
            _buildSection(
              title: 'DEARY',
              children: [
                _buildSpeedGrid(),
              ],
            ),

            const SizedBox(height: 24),

            // WiFi Config Section
            _buildSection(
              title: '# WiFi Config',
              children: [
                _buildConfigRow('SSID', _ssidController),
                _buildConfigRow('PASSWORD', _passwordController),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UBAH',
                  onPressed: _updateWiFi,
                  enabled: widget.socketService.isConnected,
                ),
                const SizedBox(height: 20),
                _buildSubSection(
                  title: 'KALIBRASI REMOT',
                  buttonText: 'MULAI',
                  onPressed: _startCalibration,
                  enabled: widget.socketService.isConnected,
                ),
                const SizedBox(height: 16),
                const Text(
                  'MaNo type',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Mitra ID Section
            _buildSection(
              title: '# Mitra ID',
              children: [
                _buildTextField(
                  controller: _mitraIdController,
                  hintText: 'Masukkan Mitra ID',
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  text: 'UPDATE',
                  onPressed: _updateMitraID,
                  enabled: widget.socketService.isConnected,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // User Info Section
            _buildSection(
              title: '# Aktivasi',
              children: [
                _buildSubSection(
                  title: 'USERSI',
                  children: [
                    _buildSerialRow('Serial Number', 'COPY', 'BUY NOW'),
                    _buildSerialRow('Kode Aktivasi', 'PASTE', 'AKTIVASI', onActivate: _activateLicense),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSubSection(
                  title: '',
                  children: [
                    _buildActionButton(
                      text: 'RESET PABRIK',
                      onPressed: _resetFactory,
                      enabled: widget.socketService.isConnected,
                      backgroundColor: AppColors.errorRed,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      text: 'CHECK UPDATE',
                      onPressed: _checkUpdate,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      text: 'UPLOAD FIRMWARE',
                      onPressed: _uploadFirmware,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildActionButton(
                  text: 'HUBUNGI KAMI',
                  onPressed: _contactSupport,
                  backgroundColor: AppColors.darkGrey,
                  foregroundColor: AppColors.neonGreen,
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.socketService.isConnected 
              ? AppColors.successGreen 
              : AppColors.errorRed,
          width: 2,
        ),
      ),
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
            child: Text(
              widget.socketService.isConnected 
                  ? 'Terhubung ke Device' 
                  : 'DISCONNECTED - Tap Connect di Dashboard',
              style: TextStyle(
                color: widget.socketService.isConnected 
                    ? AppColors.successGreen 
                    : AppColors.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (!widget.socketService.isConnected)
            Icon(
              Icons.warning_amber,
              color: AppColors.errorRed,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSubSection({
    required String title, 
    List<Widget>? children, 
    String? buttonText, 
    Function()? onPressed,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (children != null) ...children,
        if (buttonText != null && onPressed != null) 
          _buildActionButton(
            text: buttonText, 
            onPressed: onPressed,
            enabled: enabled,
          ),
      ],
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.pureWhite),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.pureWhite.withOpacity(0.6)),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required Function() onPressed,
    bool enabled = true,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.neonGreen,
          foregroundColor: foregroundColor ?? AppColors.primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: AppColors.darkGrey,
          disabledForegroundColor: AppColors.pureWhite.withOpacity(0.5),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.neonGreen,
          activeTrackColor: AppColors.neonGreen.withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildSettingRow({required String title, required Widget child}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildSpeedSelector() {
    return DropdownButton<String>(
      value: _selectedSpeed,
      dropdownColor: AppColors.darkGrey,
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 12,
      ),
      underline: Container(
        height: 1,
        color: AppColors.neonGreen,
      ),
      icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen, size: 20),
      items: _speedOptions.map((String speed) {
        return DropdownMenuItem<String>(
          value: speed,
          child: Text(
            '$speed (${_speedValues[speed]}ms)',
            style: const TextStyle(
              color: AppColors.pureWhite,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSpeed = value!;
        });
      },
    );
  }

  Widget _buildCheckbox(bool value) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? AppColors.neonGreen : AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: value
          ? Icon(Icons.check, size: 16, color: AppColors.primaryBlack)
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label :',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
          Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2,
      ),
      itemCount: _speedOptions.length,
      itemBuilder: (context, index) {
        final speed = _speedOptions[index];
        final isSelected = _selectedSpeed == speed;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpeed = speed;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.neonGreen : AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speed,
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_speedValues[speed]}',
                  style: TextStyle(
                    color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfigRow(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField(controller: controller, hintText: ''),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSerialRow(String label, String leftButton, String rightButton, {Function()? onActivate}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSmallButton(leftButton, () {
            _showSnackbar('$leftButton: $label');
          }),
          const SizedBox(width: 4),
          _buildSmallButton(
            rightButton, 
            onActivate ?? () {
              _showSnackbar('$rightButton: $label');
            },
            enabled: widget.socketService.isConnected || onActivate == null,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallButton(String text, Function() onPressed, {bool enabled = true}) {
    return Container(
      height: 25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: enabled ? AppColors.neonGreen : AppColors.darkGrey,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: enabled ? AppColors.neonGreen : AppColors.darkGrey,
        ),
      ),
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? AppColors.primaryBlack : AppColors.pureWhite.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}