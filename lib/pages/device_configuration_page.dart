import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/services/config_service.dart';
import 'package:iTen/services/preferences_service.dart';
import 'package:iTen/services/socket_service.dart';

class DeviceConfigurationPage extends StatefulWidget {
  final SocketService socketService;

  const DeviceConfigurationPage({super.key, required this.socketService});

  @override
  State<DeviceConfigurationPage> createState() =>
      _DeviceConfigurationPageState();
}

class _DeviceConfigurationPageState extends State<DeviceConfigurationPage> {
  final PreferencesService _preferencesService = PreferencesService();
  final ConfigService _configService = ConfigService();

  // State variables
  bool _isScanning = false;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Device Configuration variables
  int _selectedDeviceCount = 1;
  List<DeviceSection> _deviceSections = [];
  final List<TextEditingController> _emailControllers = [];
  final List<TextEditingController> _idControllers = [];
  final List<TextEditingController> _channelControllers = [];

  List<String> _logMessages = [];

  // Stream subscriptions
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // Key untuk menyimpan device sections di preferences
  static const String _deviceSectionsKey = 'device_sections';

  @override
  void initState() {
    super.initState();
    _initializeDeviceSections();
    _setupSocketListeners();
    _loadSavedDeviceSections();
  }

  void _setupSocketListeners() {
    _messageSubscription = widget.socketService.messages.listen((message) {
      _handleSocketMessage(message);
    });

    _connectionSubscription = widget.socketService.connectionStatus.listen((
      connected,
    ) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isConnecting = false;
        });
      }
    });
  }

  // Method untuk load saved device sections dari preferences
  Future<void> _loadSavedDeviceSections() async {
    try {
      await _preferencesService.initialize();
      final savedSections = await _preferencesService.getUserSetting(
        _deviceSectionsKey,
      );

      if (savedSections != null && savedSections is List) {
        setState(() {
          for (
            int i = 0;
            i < savedSections.length && i < _deviceSections.length;
            i++
          ) {
            final sectionData = savedSections[i] as Map<String, dynamic>;
            _emailControllers[i].text = sectionData['email'] ?? '';
            _idControllers[i].text = sectionData['id'] ?? '';
            _channelControllers[i].text =
                sectionData['channelCount']?.toString() ?? '';

            _deviceSections[i] = DeviceSection(
              id: sectionData['id'] ?? '',
              email: sectionData['email'] ?? '',
              channelCount: sectionData['channelCount'] ?? 0,
              deviceCount: i + 1,
            );
          }
        });
        _addLogMessage('📂 Loaded saved device sections from preferences');
      }
    } catch (e) {
      print('❌ Error loading saved device sections: $e');
    }
  }

  // Method untuk save device sections ke preferences
  Future<void> _saveDeviceSections() async {
    try {
      final sectionsToSave = _deviceSections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        return {
          'id': _idControllers[index].text,
          'email': _emailControllers[index].text,
          'channelCount': int.tryParse(_channelControllers[index].text) ?? 0,
          'deviceCount': section.deviceCount,
        };
      }).toList();

      await _preferencesService.saveUserSetting(
        _deviceSectionsKey,
        sectionsToSave,
      );
      _addLogMessage('💾 Device sections saved to preferences');
    } catch (e) {
      print('❌ Error saving device sections: $e');
    }
  }

  void _initializeDeviceSections() {
    _updateDeviceSections();
  }

  void _updateDeviceSections() {
    setState(() {
      // Hitung jumlah device eksternal
      int externalDeviceCount = _selectedDeviceCount - 1;
      if (externalDeviceCount < 0) externalDeviceCount = 0;

      // Clear existing controllers
      for (var controller in _emailControllers) {
        controller.dispose();
      }
      for (var controller in _idControllers) {
        controller.dispose();
      }
      for (var controller in _channelControllers) {
        controller.dispose();
      }

      _emailControllers.clear();
      _idControllers.clear();
      _channelControllers.clear();
      _deviceSections.clear();

      // Buat sections HANYA untuk device eksternal
      for (int i = 0; i < externalDeviceCount; i++) {
        _emailControllers.add(TextEditingController());
        _idControllers.add(TextEditingController());
        _channelControllers.add(TextEditingController());

        _deviceSections.add(
          DeviceSection(
            id: '', // ID akan di-load dari preferences
            email: '',
            channelCount: 0,
            deviceCount: i + 2, // Device count 2, 3, 4, 5
          ),
        );
      }
    });
  }

  void _onDeviceCountChanged(int? newValue) {
    if (newValue != null) {
      setState(() {
        _selectedDeviceCount = newValue;
      });
      _updateDeviceSections();
      _saveDeviceSections(); // Save ketika jumlah device berubah
    }
  }

  Future<void> _scanQRCodeForSection(int sectionIndex) async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final result = await BarcodeScanner.scan();

      if (result.type == ResultType.Barcode) {
        await _processScannedQRCodeForSection(result.rawContent, sectionIndex);
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

  Future<void> _processScannedQRCodeForSection(
    String qrData,
    int sectionIndex,
  ) async {
    _addLogMessage('📷 Scanned for Modul ${sectionIndex + 1}: $qrData');

    try {
      final parts = qrData.split(',');
      if (parts.length >= 3) {
        final email = parts[0].trim();
        final id = parts[1].trim();
        final channel = int.tryParse(parts[2].trim()) ?? 0;

        setState(() {
          _emailControllers[sectionIndex].text = email;
          _idControllers[sectionIndex].text = id;
          _channelControllers[sectionIndex].text = channel.toString();

          _deviceSections[sectionIndex] = DeviceSection(
            id: id,
            email: email,
            channelCount: channel,
            deviceCount: sectionIndex + 1,
          );
        });

        _addLogMessage(
          '✅ Modul ${sectionIndex + 1} updated: $email, $id, $channel channels',
        );

        // Simpan ke preferences
        await _saveDeviceSections();

        // Otomatis kirim data ke socket setelah scan
        _sendDeviceDataToSocket(sectionIndex);
      } else {
        _showSnackbar('Format QR Code tidak valid. Harus: email,id,channel');
      }
    } catch (e) {
      _showSnackbar('Error processing QR code: $e');
    }
  }

  void _sendDeviceDataToSocket(int sectionIndex) {
    // sectionIndex = 0, 1, 2...
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    // --- PERUBAHAN ---
    final deviceNumber = sectionIndex + 2; // index 0 adalah device ke-2
    // --- SELESAI ---

    final email = _emailControllers[sectionIndex].text.trim();
    final id = _idControllers[sectionIndex].text.trim();
    final channel = _channelControllers[sectionIndex].text.trim();

    if (email.isEmpty || id.isEmpty || channel.isEmpty) {
      _showSnackbar('Data Modul $deviceNumber belum lengkap');
      return;
    }

    // Format: XD[jumlah device],[device count],[email],[mac],[channel]
    final command = 'XD$_selectedDeviceCount,$deviceNumber,$email,$id,$channel';
    widget.socketService.send(command);

    _addLogMessage('📤 Sent to socket: $command');
    _showSnackbar('Data Modul $deviceNumber dikirim ke device');
  }

  // Method untuk kirim data manual (tanpa scan)
  void _sendManualDataToSocket(int sectionIndex) {
    // sectionIndex = 0, 1, 2...
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    // --- PERUBAHAN ---
    final deviceNumber = sectionIndex + 2; // index 0 adalah device ke-2
    // --- SELESAI ---

    final email = _emailControllers[sectionIndex].text.trim();
    final id = _idControllers[sectionIndex].text.trim();
    final channel = _channelControllers[sectionIndex].text.trim();

    if (email.isEmpty || id.isEmpty || channel.isEmpty) {
      _showSnackbar(
        'Harap lengkapi data Modul $deviceNumber terlebih dahulu',
      );
      return;
    }

    // Format: XD[jumlah device],[device count],[email],[mac],[channel]
    final command = 'XD$_selectedDeviceCount,$deviceNumber,$email,$id,$channel';
    widget.socketService.send(command);

    _addLogMessage('📤 Manual send: $command');
    _showSnackbar('Data Modul $deviceNumber dikirim manual ke device');
  }

  void _setupMyDevice() async {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    final config = await _preferencesService.getDeviceConfig();
    if (config == null) {
      _showSnackbar('Device config tidak ditemukan');
      return;
    }

    // Kirim command XD untuk setup device sendiri
    // Format: XD[jumlah device],[device count],[email],[mac],[channel]
    final command =
        'XD$_selectedDeviceCount,1,${config.email},${config.mac},${config.jumlahChannel}';
    widget.socketService.send(command);

    _addLogMessage(
      '🔧 Setup device saya: ${config.email} - ${config.mac} - ${config.jumlahChannel} channels',
    );
    _showSnackbar('Device saya berhasil di-setup');
  }

  void _sendRemoteCommand(String command) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    if (command == 'Z') {
      // Tombol Auto - kirim XRZ
      widget.socketService.send('XRZ');
      _addLogMessage('🔄 Auto mode diaktifkan');
    } else {
      // Tombol 1-13 - kirim XRA sampai XRM
      final remoteCommand = 'XR${String.fromCharCode(64 + int.parse(command))}';
      widget.socketService.send(remoteCommand);
      _addLogMessage('🎛️ Remote command: $remoteCommand');
    }
  }

  Future<void> _connectToDevice() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
    });

    await widget.socketService.connect();

    if (widget.socketService.isConnected) {
      widget.socketService.requestConfig();
    }
  }

  void _disconnectFromDevice() {
    widget.socketService.disconnect();
    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });
  }

  void _handleSocketMessage(String message) {
    print('DeviceConfigurationPage received: $message');
    _addLogMessage('📥: $message');

    if (message.startsWith('config2,')) {
      _handleConfigShowResponse(message);
    } else if (message.startsWith('info,')) {
      final infoMessage = message.substring(5);
      _showSnackbar(infoMessage);
      _addLogMessage('💡: $infoMessage');
    } else if (message.startsWith('CONFIG_UPDATED:')) {
      _addLogMessage('🔄 Config updated');
    }
  }

  void _handleConfigShowResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 6) {
      _addLogMessage('✅ Mode Show aktif - Firmware: ${parts[1]}');
    }
  }

  Widget _buildConnectionButton() {
    if (_isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warningYellow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warningYellow),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warningYellow,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Connecting...',
              style: TextStyle(
                color: AppColors.warningYellow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isConnected) {
      return GestureDetector(
        onTap: () => _showConnectionMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.successGreen),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Connected',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 12, color: AppColors.successGreen),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _connectToDevice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.errorRed),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 12, color: AppColors.errorRed),
            const SizedBox(width: 6),
            Text(
              'Connect',
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceConfigurationSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DEVICE CONFIGURATION',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Dropdown untuk jumlah device
            _buildDeviceCountDropdown(),
            const SizedBox(height: 16),

            // --- PERUBAHAN ---
            // Tampilkan card "My Device" (Modul 1)
            _buildMyDeviceSectionCard(),

            // Tampilkan device eksternal jika _selectedDeviceCount > 1
            if (_selectedDeviceCount > 1) ...[
              const SizedBox(height: 16),
              const Text(
                'EXTERNAL DEVICES',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // List device sections (Modul 2, 3, ...)
              ..._deviceSections.asMap().entries.map((entry) {
                final index = entry.key; // 0, 1, 2...
                final section = entry.value;
                // index 0 -> deviceNumber 2
                final deviceNumber = index + 2;

                return _buildDeviceSectionCard(section, index, deviceNumber);
              }),
            ],
            // --- SELESAI ---
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCountDropdown() {
    return Row(
      children: [
        const Text(
          'Jumlah Device:',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _selectedDeviceCount,
          items: List.generate(5, (index) => index + 1)
              .map(
                (count) => DropdownMenuItem(
                  value: count,
                  child: Text(
                    '$count',
                    style: const TextStyle(color: AppColors.primaryBlack),
                  ),
                ),
              )
              .toList(),
          onChanged: _onDeviceCountChanged,
          dropdownColor: AppColors.neonGreen,
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.pureWhite),
          border: const OutlineInputBorder(),
          // Ganti border jadi abu-abu biar kelihatan "disabled"
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.pureWhite.withOpacity(0.3)),
          ),
          filled: true,
          fillColor: AppColors.primaryBlack.withOpacity(0.5),
        ),
        style: TextStyle(color: AppColors.pureWhite.withOpacity(0.7)),
      ),
    );
  }

  Widget _buildMyDeviceSectionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: FutureBuilder(
        // Kita pakai FutureBuilder untuk ambil config HP ini
        future: _preferencesService.getDeviceConfig(),
        builder: (context, snapshot) {
          String email = 'Loading...';
          String id = 'Loading...';
          String channel = 'Loading...';

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final config = snapshot.data;
            email = config?.email ?? 'Not Set';
            id = config?.mac ?? 'Not Set';
            channel = config?.jumlahChannel.toString() ?? '0';
          } else if (snapshot.hasError) {
            email = 'Error';
            id = 'Error';
            channel = 'Error';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Modul 1 (My Device)',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Tombol Setup (Kirim data "My Device")
                  _buildSmallButton(
                    'SETUP',
                    _setupMyDevice, // Memanggil fungsi yang sudah ada
                    enabled: widget.socketService.isConnected,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input fields read-only
              _buildReadOnlyTextField(label: 'ID Device (MAC)', value: id),
              _buildReadOnlyTextField(label: 'Email', value: email),
              _buildReadOnlyTextField(label: 'Jumlah Channel', value: channel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceSectionCard(
    DeviceSection section,
    int index,
    int deviceNumber,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Modul $deviceNumber',
                style: const TextStyle(
                  color: AppColors.neonGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Tombol Kirim Manual
              _buildSmallButton(
                'KIRIM',

                () => _sendManualDataToSocket(index),

                enabled: widget.socketService.isConnected,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Input fields
          TextField(
            controller: _idControllers[index],
            decoration: const InputDecoration(
              labelText: 'ID Device (MAC)',
              labelStyle: TextStyle(color: AppColors.pureWhite),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.neonGreen),
              ),
            ),
            style: const TextStyle(color: AppColors.pureWhite),
            onChanged: (_) => _saveDeviceSections(), // Auto-save ketika diubah
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _emailControllers[index],
            decoration: const InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: AppColors.pureWhite),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.neonGreen),
              ),
            ),
            style: const TextStyle(color: AppColors.pureWhite),
            onChanged: (_) => _saveDeviceSections(), // Auto-save ketika diubah
          ),
          const SizedBox(height: 8),

          TextField(
  controller: _channelControllers[index],
  decoration: const InputDecoration(
    labelText: 'Jumlah Channel',
    labelStyle: TextStyle(color: AppColors.pureWhite),
    border: OutlineInputBorder(), // Border default
    enabledBorder: OutlineInputBorder( // Border saat field aktif
      borderSide: BorderSide(color: AppColors.neonGreen),
    ),
  ),
  keyboardType: TextInputType.number, // Memastikan input hanya angka
  style: const TextStyle(color: AppColors.pureWhite),
  onChanged: (_) => _saveDeviceSections(), // Auto-save ketika diubah
),
          const SizedBox(height: 12),

          // Tombol Scan
          _buildScanButton(index),
        ],
      ),
    );
  }

  Widget _buildScanButton(int index) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isScanning ? null : () => _scanQRCodeForSection(index),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.primaryBlack,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        icon: _isScanning
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlack,
                ),
              )
            : const Icon(Icons.qr_code_scanner, size: 18),
        label: Text(
          _isScanning ? 'SCANNING...' : 'SCAN QR CODE',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSetupMyDeviceButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _setupMyDevice,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neonGreen,
          foregroundColor: AppColors.primaryBlack,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.device_hub),
        label: const Text(
          'SETUP DEVICE SAYA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSmallButton(
    String text,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: enabled ? AppColors.neonGreen : AppColors.darkGrey,
        borderRadius: BorderRadius.circular(6),
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
            color: enabled
                ? AppColors.primaryBlack
                : AppColors.pureWhite.withOpacity(0.5),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteButton(
    String label, {
    VoidCallback? onPressed,
    bool isAuto = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isAuto ? AppColors.warningYellow : AppColors.neonGreen,
        foregroundColor: AppColors.primaryBlack,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              height: 120,
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

  void _showConnectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connection Menu',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isConnected ? 'Connected to Device' : 'Disconnected',
                        style: TextStyle(
                          color: _isConnected
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (_isConnected) ...[
                _buildConnectionAction(
                  icon: Icons.refresh,
                  title: 'Reconnect',
                  onTap: _connectToDevice,
                ),
                _buildConnectionAction(
                  icon: Icons.settings,
                  title: 'Request Config',
                  onTap: () {
                    widget.socketService.requestConfig();
                    Navigator.pop(context);
                    _showSnackbar('Requesting device config...');
                  },
                ),
                _buildConnectionAction(
                  icon: Icons.wifi_off,
                  title: 'Disconnect',
                  onTap: () {
                    _disconnectFromDevice();
                    Navigator.pop(context);
                  },
                  isDestructive: true,
                ),
              ],
              // else [
              //   _buildConnectionAction(
              //     icon: Icons.wifi,
              //     title: 'Connect to Device',
              //     onTap: () {
              //       _connectToDevice();
              //       Navigator.pop(context);
              //     },
              //   ),
              // ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionAction({
    required IconData icon,
    required String title,
    required Function() onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.errorRed : AppColors.neonGreen,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.errorRed : AppColors.pureWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  void _addLogMessage(String message) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('T')[1]
        .split('.')[0];
    final logMessage = '[$timestamp] $message';

    setState(() {
      _logMessages.add(logMessage);
      if (_logMessages.length > 50) {
        _logMessages.removeAt(0);
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(message, style: TextStyle(color: AppColors.primaryBlack)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDeviceConfigurationSection(),
            const SizedBox(height: 16),
            // _buildRemoteControlSection(),
            // const SizedBox(height: 16),
            // _buildLogSection(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();

    // Dispose semua controller untuk device sections
    for (var controller in _emailControllers) {
      controller.dispose();
    }
    for (var controller in _idControllers) {
      controller.dispose();
    }
    for (var controller in _channelControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}

// Model untuk device Modul
class DeviceSection {
  final String id;
  final String email;
  final int channelCount;
  final int deviceCount;

  DeviceSection({
    required this.id,
    required this.email,
    required this.channelCount,
    required this.deviceCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'channelCount': channelCount,
      'deviceCount': deviceCount,
    };
  }

  factory DeviceSection.fromMap(Map<String, dynamic> map) {
    return DeviceSection(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      channelCount: map['channelCount'] ?? 0,
      deviceCount: map['deviceCount'] ?? 0,
    );
  }
}
