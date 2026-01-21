import 'dart:async';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/config_show_model.dart'; // IMPORT MODEL BARU
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

  // --- TAMBAHKAN VARIABEL UNTUK SPEED RUN ---
  final TextEditingController _speedRunController = TextEditingController();
  ConfigShowModel? _currentConfigShow;

  List<String> _logMessages = [];

  // Stream subscriptions
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  // Key untuk menyimpan device sections di preferences
  static const String _deviceSectionsKey = 'device_sections';

  @override
void initState() {
  super.initState();

  _setupSocketListeners();
  _restoreState();

  if (widget.socketService.isConnected) {
    debugPrint("✅ Connected, sending XM10");
    widget.socketService.send("XM11");
  }

  widget.socketService.onConnectionChanged = (isConnected) {
    if (isConnected) {
      debugPrint("✅ Connected, sending XM10");
      widget.socketService.send("XM11");
      _loadConfigShowData();
    } else {
      debugPrint("❌ Disconnected");
    }
  };
}
Future<void> _restoreState() async {
  await _preferencesService.initialize();

  final savedDeviceCount =
      await _preferencesService.getUserSetting('selected_device_count');

  if (savedDeviceCount != null && mounted) {
    setState(() {
      _selectedDeviceCount = savedDeviceCount;
    });
  }

  _updateDeviceSections();

  await _loadSavedDeviceSections();

  await _loadConfigShowData();
}

  // TAMBAHKAN: Load config show data
  Future<void> _loadConfigShowData() async {
    try {
      await _preferencesService.initialize();
      final configShow = await _preferencesService.getConfigShow();
      
      if (mounted) {
        setState(() {
          _currentConfigShow = configShow;
          if (configShow != null) {
            _speedRunController.text = configShow.speedRun.toString();
          } else {
            _speedRunController.text = '50'; // Default value
          }
        });
      }
    } catch (e) {
      print('❌ Error loading config show data: $e');
    }
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

  // TAMBAHKAN: Method untuk set speed run
  void _setSpeedRun() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    final speedText = _speedRunController.text.trim();
    if (speedText.isEmpty) {
      _showSnackbar('Masukkan nilai speed run');
      return;
    }

    final speed = int.tryParse(speedText);
    if (speed == null || speed < 1 || speed > 999) {
      _showSnackbar('Speed run harus antara 1-999');
      return;
    }

    // Format: XS(delaynya 3digit)
    final command = 'XS${speed.toString().padLeft(3, '0')}';
    widget.socketService.send(command);

    _addLogMessage('⚡ Set speed run: $speed ms');
    _showSnackbar('Speed run diatur ke $speed ms');

    // Update local config
    if (_currentConfigShow != null) {
      final updatedConfig = _currentConfigShow!.copyWith(speedRun: speed);
      _preferencesService.saveConfigShow(updatedConfig);
      setState(() {
        _currentConfigShow = updatedConfig;
      });
    }
  }

  // TAMBAHKAN: Method untuk reset speed run ke default
  void _resetSpeedRun() {
    setState(() {
      _speedRunController.text = '50'; // Default value
    });
    _addLogMessage('🔄 Speed run direset ke default: 50 ms');
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
        final email = parts[1].trim();
        final id = parts[0].trim();
        final channel = int.tryParse(parts[2].trim()) ?? 0;
print("owner is == $email");
print("id is == $id");
print("channel is == $channel");
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
        _showSnackbar('Format QR Code tidak valid. Harus: nama,id,channel');
      }
    } catch (e) {
      _showSnackbar('Error processing QR code: $e');
    }
  }

  void _sendDeviceDataToSocket(int sectionIndex) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    final deviceNumber = sectionIndex + 2; // index 0 adalah device ke-2

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
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    final deviceNumber = sectionIndex + 2; // index 0 adalah device ke-2

    final email = _emailControllers[sectionIndex].text.trim();
    final id = _idControllers[sectionIndex].text.trim();
    final channel = _channelControllers[sectionIndex].text.trim();

    if (email.isEmpty || id.isEmpty || channel.isEmpty) {
      _showSnackbar(
        'Harap lengkapi data Modul $deviceNumber terlebih dahulu',
      );
      return;
    }

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

  Future<void> _connectToDevice() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
    });

    await widget.socketService.connect();

    if (widget.socketService.isConnected) {
      widget.socketService.requestConfigShow(); // Request config show, bukan config biasa
      _loadConfigShowData(); // Load config show data setelah terkoneksi
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
    } else if (message.startsWith('CONFIG2_UPDATED:')) {
      _addLogMessage('🔄 Config show updated');
      _loadConfigShowData(); // Reload data ketika config show diupdate
    }
  }

  void _handleConfigShowResponse(String message) {
    try {
      final configShow = ConfigShowModel.fromConfig2String(message);
      _preferencesService.saveConfigShow(configShow);
      
      if (mounted) {
        setState(() {
          _currentConfigShow = configShow;
          _speedRunController.text = configShow.speedRun.toString();
        });
      }
      
      _addLogMessage('✅ Config show loaded - Speed: ${configShow.speedRun}ms');
    } catch (e) {
      _addLogMessage('❌ Error parsing config show: $e');
    }
  }

  // TAMBAHKAN: Widget untuk speed run configuration
  Widget _buildSpeedRunSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SPEED RUN CONFIGURATION',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_currentConfigShow != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonGreen),
                    ),
                    child: Text(
                      'Current: ${_currentConfigShow!.speedRun}ms',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _speedRunController,
                    decoration: const InputDecoration(
                      labelText: 'Speed Run (ms)',
                      labelStyle: TextStyle(color: AppColors.pureWhite),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                      hintText: '50',
                    ),
                    style: const TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    _buildSmallButton(
                      'SET',
                      _setSpeedRun,
                      enabled: widget.socketService.isConnected,
                    ),
                    const SizedBox(height: 4),
                    _buildSmallButton(
                      'RESET',
                      _resetSpeedRun,
                      enabled: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Text(
              'Rekomendasi: 30-200 ms (semakin kecil semakin cepat)',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
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
                  _buildSmallButton(
                    'SETUP',
                    _setupMyDevice,
                    enabled: widget.socketService.isConnected,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Input fields read-only
              _buildReadOnlyTextField(label: 'ID Device', value: id),
              _buildReadOnlyTextField(label: 'Owner', value: email),
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
            onChanged: (_) => _saveDeviceSections(),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _emailControllers[index],
            decoration: const InputDecoration(
              labelText: 'Owner',
              labelStyle: TextStyle(color: AppColors.pureWhite),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.neonGreen),
              ),
            ),
            style: const TextStyle(color: AppColors.pureWhite),
            onChanged: (_) => _saveDeviceSections(),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _channelControllers[index],
            decoration: const InputDecoration(
              labelText: 'Jumlah Channel',
              labelStyle: TextStyle(color: AppColors.pureWhite),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.neonGreen),
              ),
            ),
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.pureWhite),
            onChanged: (_) => _saveDeviceSections(),
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
            // TAMBAHKAN speed run section di atas device configuration
            _buildSpeedRunSection(),
            const SizedBox(height: 16),
            _buildDeviceConfigurationSection(),
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
    _speedRunController.dispose(); // TAMBAHKAN: Dispose speed run controller

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