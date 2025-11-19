
  import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/preferences_service.dart';
import 'package:iTen/services/socket_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

  class SettingsPage extends StatefulWidget {
    final SocketService socketService;

    const SettingsPage({super.key, required this.socketService});

    @override
    State<SettingsPage> createState() => _SettingsPageState();
  }

  class _SettingsPageState extends State<SettingsPage> {
    bool _welcomeModeEnabled = true;
    int _selectedDuration = 3;
    int _selectedChannel = 8;
    int _selectedAnimationIndex = 0;
    String? _selectedWelcomeAnimation = 'None'; // INISIALISASI DEFAULT

    int _maxChannels = 8;
    ConfigModel? config;

    final PreferencesService _preferencesService = PreferencesService();

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _ssidController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _serialController = TextEditingController();
    final TextEditingController _activationController = TextEditingController();
    final TextEditingController _mitraIdController = TextEditingController();
    final Map<String, TextEditingController> _speedControllers = {
      'LAMBAT': TextEditingController(text: '500'),
      'SEDANG': TextEditingController(text: '200'),
      'CEPAT': TextEditingController(text: '100'),
      'CEPAAT': TextEditingController(text: '50'),
    };

    // --- PERBAIKAN: Tambahkan deviceId ke semua animasi ---
    static final List<Map<String, dynamic>> _defaultAnimationsData = [
      {
        'name': 'None',
        'channelCount': 0,
        'animationLength': 0,
        'description': 'tidak ada animasi',
        'delayData': '0',
        'frameData': [],
        'deviceId': 0,
      },
      {
        'name': 'None',
        'channelCount': 0,
        'animationLength': 0,
        'description': 'tidak ada animasi',
        'delayData': '0',
        'frameData': [],
        'deviceId': 1,
      },
      {
        'name': 'Animation 03 - Baling - Baling',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'Propeller rotation effect',
        'delayData': '80',
        'frameData': [],
        'deviceId': 3,
      },
      {
        'name': 'Animation 04 - X Loop',
        'channelCount': 4,
        'animationLength': 12,
        'description': 'X pattern looping animation',
        'delayData': '120',
        'frameData': [],
        'deviceId': 4,
      },
      {
        'name': 'Animation 05 - X Run',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'X pattern running effect',
        'delayData': '100',
        'frameData': [],
        'deviceId': 5,
      },
      {
        'name': 'Animation 06 - Baling Kedip',
        'channelCount': 4,
        'animationLength': 6,
        'description': 'Blinking propeller effect',
        'delayData': '60',
        'frameData': [],
        'deviceId': 6,
      },
      {
        'name': 'Animation 07 - Left Right',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'Left to right movement',
        'delayData': '80',
        'frameData': [],
        'deviceId': 7,
      },
      {
        'name': 'Animation 08 - Random Bit',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Random bit pattern animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 8,
      },
      {
        'name': 'Animation 09 - Swap Fill',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'Swap and fill animation',
        'delayData': '80',
        'frameData': [],
        'deviceId': 9,
      },
      {
        'name': 'Animation 10 - Every 2 Bit',
        'channelCount': 4,
        'animationLength': 12,
        'description': 'Every second bit animation',
        'delayData': '120',
        'frameData': [],
        'deviceId': 10,
      },
      {
        'name': 'Animation 11 - Swap Fill LR',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Left-right swap fill animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 11,
      },
      {
        'name': 'Animation 12 - Up Run',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'Upward running animation',
        'delayData': '80',
        'frameData': [],
        'deviceId': 12,
      },
      {
        'name': 'Animation 13 - Up Down Run',
        'channelCount': 4,
        'animationLength': 12,
        'description': 'Up-down running animation',
        'delayData': '120',
        'frameData': [],
        'deviceId': 13,
      },
      {
        'name': 'Animation 14 - Blinking LR',
        'channelCount': 4,
        'animationLength': 6,
        'description': 'Left-right blinking animation',
        'delayData': '60',
        'frameData': [],
        'deviceId': 14,
      },
      {
        'name': 'Animation 15 - Blinking UD',
        'channelCount': 4,
        'animationLength': 6,
        'description': 'Up-down blinking animation',
        'delayData': '60',
        'frameData': [],
        'deviceId': 15,
      },
      {
        'name': 'Animation 16 - Random Corner',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Random corner animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 16,
      },
      {
        'name': 'Animation 17 - Fill Circle',
        'channelCount': 4,
        'animationLength': 15,
        'description': 'Circular fill animation',
        'delayData': '150',
        'frameData': [],
        'deviceId': 17,
      },
      {
        'name': 'Animation 18 - X Pulse',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'X pattern pulsing animation',
        'delayData': '80',
        'frameData': [],
        'deviceId': 18,
      },
      {
        'name': 'Animation 19 - X Blink',
        'channelCount': 4,
        'animationLength': 6,
        'description': 'X pattern blinking animation',
        'delayData': '60',
        'frameData': [],
        'deviceId': 19,
      },
      {
        'name': 'Animation 20 - O Left Right',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'O pattern left-right animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 20,
      },
      {
        'name': 'Animation 21 - O LR',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'O pattern left-right simplified',
        'delayData': '80',
        'frameData': [],
        'deviceId': 21,
      },
      {
        'name': 'Animation 22 - O Out',
        'channelCount': 4,
        'animationLength': 12,
        'description': 'O pattern outward animation',
        'delayData': '120',
        'frameData': [],
        'deviceId': 22,
      },
      {
        'name': 'Animation 23 - Sweeper',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Sweeping animation effect',
        'delayData': '100',
        'frameData': [],
        'deviceId': 23,
      },
      {
        'name': 'Animation 24 - In Out',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'In-out animation pattern',
        'delayData': '80',
        'frameData': [],
        'deviceId': 24,
      },
      {
        'name': 'Animation 25 - Bouncing',
        'channelCount': 4,
        'animationLength': 12,
        'description': 'Bouncing animation effect',
        'delayData': '120',
        'frameData': [],
        'deviceId': 25,
      },
      {
        'name': 'Animation 26 - Bouncing LR',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Left-right bouncing animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 26,
      },
      {
        'name': 'Animation 27 - Bouncing Blink',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'Bouncing with blinking effect',
        'delayData': '80',
        'frameData': [],
        'deviceId': 27,
      },
      {
        'name': 'Animation 28 - Fill in',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Fill in animation pattern',
        'delayData': '100',
        'frameData': [],
        'deviceId': 28,
      },
      {
        'name': 'Animation 29 - X swap',
        'channelCount': 4,
        'animationLength': 8,
        'description': 'X pattern swap animation',
        'delayData': '80',
        'frameData': [],
        'deviceId': 29,
      },
      {
        'name': 'Animation 30 - Fill Right',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Right fill animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 30,
      },
      {
        'name': 'Animation 31 - Fill Down',
        'channelCount': 4,
        'animationLength': 10,
        'description': 'Downward fill animation',
        'delayData': '100',
        'frameData': [],
        'deviceId': 31,
      },
    ];

    String _firmwareVersion = '-';
    String _deviceId = '';
    String _licenseLevel = '';
    String _deviceChannel = '';
    String _currentEmail = '';
    String _currentSSID = '';
    String _currentPassword = '';
    bool _isCalibrating = false;
    String _currentCalibrationStep = 'A';
    
    // --- PERBAIKAN: Tambahkan stream subscriptions ---
    StreamSubscription<String>? _messageSubscription;
    StreamSubscription<String>? _calibrationSubscription;
    
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
      _initializeApp();
      _setupSocketListeners(); // Pindahkan ke sini
    }

    // --- PERBAIKAN: Helper methods dengan NULL SAFETY ---
    String _safeGetString(Map<String, dynamic> map, String key) {
      final value = map[key];
      return value is String ? value : 'Unknown';
    }

    int _safeGetInt(Map<String, dynamic> map, String key) {
      final value = map[key];
      return value is int ? value : 0;
    }

  // Di dalam _initializeApp(), tambahkan validasi license setelah config loaded
  Future<void> _initializeApp() async {
    try {
      // Load config terlebih dahulu
      config = await _preferencesService.getDeviceConfig();
      print('✅ Config loaded: ${config?.devID ?? "No config"}');
      
      _selectedDuration = config?.durasiWelcome ?? 1;
      
      // Set selected welcome animation dari config
      final animIndex = config?.animWelcome ?? 0;
      
      // Validasi agar index tidak out of bounds
      final safeIndex = animIndex.clamp(0, _defaultAnimationsData.length - 1);
      
      _selectedAnimationIndex = safeIndex;
      _selectedWelcomeAnimation = _defaultAnimationsData[safeIndex]['name'] as String;

      print("Animasi yang dipilih: $_selectedWelcomeAnimation, UI Index: $safeIndex, Device ID: ${safeIndex + 1}");

      // Initialize data dengan config yang sudah diload
      _initializeData();
      _setupSocketListeners();
      
      setState(() {});
    } catch (e) {
      print('❌ Error initializing app: $e');
      _initializeData();
      _setupSocketListeners();
    }

    // Request config data saat page dibuka
    if (widget.socketService.isConnected) {
      widget.socketService.requestConfig();
    } else {
      // Jika tidak connected, set default license state
      setState(() {
        _licenseLevel = '0';
        _maxChannels = 0;
      });
    }
  }

    // --- PERBAIKAN: Setup socket listeners dengan mounted check ---
    void _setupSocketListeners() {
      _messageSubscription?.cancel(); // Cancel existing

      _messageSubscription = widget.socketService.messages.listen((message) {
        if (!mounted) return; // CHECK MOUNTED sebelum handle
        
        print('SettingsPage received: $message');
        _handleSocketMessage(message);
      });
    }

    void _initializeData() {
      _emailController.text = config?.email ?? 'example@gmail.com';
      _ssidController.text = config?.ssid ?? 'MaNo';
      _passwordController.text = config?.password ?? '11223344';
      _serialController.text = config?.devID ?? "Serial Number Kamu";
      _activationController.text = '';
      _mitraIdController.text = config?.mitraID ?? '';

      print('📊 Initialized data with config: ${config != null ? "Yes" : "No"}');
    }

    Future<void> _copyToClipboard(String text, String message) async {
      try {
        await Clipboard.setData(ClipboardData(text: text));
        _showSnackbar('$message - Berhasil disalin!');
        print('📋 Copied to clipboard: $text');
      } catch (e) {
        _showSnackbar('Gagal menyalin: $e');
        print('❌ Error copying to clipboard: $e');
      }
    }

    Future<void> _pasteFromClipboard([TextEditingController? controller]) async {
      try {
        final clipboardData = await Clipboard.getData('text/plain');
        final pastedText = clipboardData?.text?.trim();

        if (pastedText == null || pastedText.isEmpty) {
          _showSnackbar('Tidak ada teks di clipboard');
          return;
        }

        if (controller != null) {
          controller.text = pastedText;
          _showSnackbar('Teks berhasil dipaste: "$pastedText"');
          print('📋 Pasted to field: $pastedText');
        } else {
          _showSnackbar('Teks dari clipboard: "$pastedText"');
          print('📋 Pasted text: $pastedText');
        }
      } catch (e) {
        _showSnackbar('Gagal membaca clipboard: $e');
        print('❌ Error pasting from clipboard: $e');
      }
    }
  Widget _buildWelcomeAnimationDropdown() {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: DropdownButton<int>(
        value: _selectedAnimationIndex,
        isExpanded: true,
        dropdownColor: AppColors.darkGrey,
        style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen, size: 20),
        items: _buildWelcomeAnimationItems(),
        onChanged: (int? newIndex) {
          if (newIndex != null && newIndex >= 0 && newIndex < _defaultAnimationsData.length) {
            print('🔄 Dropdown changed to index: $newIndex'); // Debug
            setState(() {
              _selectedAnimationIndex = newIndex;
              _selectedWelcomeAnimation = _defaultAnimationsData[newIndex]['name'] as String;
            });
            print('✅ State updated: $_selectedWelcomeAnimation');
          }
        },
      ),
    );
  }

  List<DropdownMenuItem<int>> _buildWelcomeAnimationItems() {
    return _defaultAnimationsData.asMap().entries.map((entry) {
      final index = entry.key;
      final animationData = entry.value;

      final animationName = animationData['name'] as String;
      final channelCount = animationData['channelCount'] as int;
      final animationLength = animationData['animationLength'] as int;
      final deviceId = index + 1;

      return DropdownMenuItem<int>(
        value: index,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    animationName,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'ID: ${deviceId.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${channelCount}C • ${animationLength}L',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
    int _getAnimationIndex(String animationName) {
    try {
      for (int i = 0; i < _defaultAnimationsData.length; i++) {
        final currentName = _safeGetString(_defaultAnimationsData[i], 'name');
        if (currentName == animationName) {
          print('🎯 Found animation "$animationName" at index: $i');
          return i;
        }
      }
      print('❌ Animation "$animationName" not found, using index 0');
      return 0; // Fallback ke index 0
    } catch (e) {
      print('❌ Error getting animation index: $e');
      return 0;
    }
  }
    int _getDeviceAnimationId(String animationName) {
      final index = _getAnimationIndex(animationName);
      if (index >= 0 && index < _defaultAnimationsData.length) {
        return _safeGetInt(_defaultAnimationsData[index], 'deviceId');
      }
      return 0;
    }

    Widget _buildSpeedInputGrid() {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _speedOptions.length,
        itemBuilder: (context, index) {
          final speed = _speedOptions[index];
          final controller = _speedControllers[speed]!;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  speed,
                  style: const TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 80,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ms',
                      hintStyle: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.5),
                        fontSize: 10,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && int.tryParse(value) == null) {
                        controller.text = value.substring(0, value.length - 1);
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'milidetik',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          );
        },
      );
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

        // Parse license level dan set max channels
        final licenseLevel = int.tryParse(_licenseLevel) ?? 0;
        _maxChannels = _getMaxChannelsByLicense(licenseLevel);
        
        // Set selected channel dari device channel, tapi hanya jika license aktif
        final deviceChannel = int.tryParse(_deviceChannel) ?? _maxChannels;
        
        if (licenseLevel > 0) {
          // License aktif - gunakan channel dari device atau max channels
          _selectedChannel = deviceChannel <= _maxChannels ? deviceChannel : _maxChannels;
        } else {
          // License tidak aktif - tetap gunakan channel yang ada, tapi nonaktifkan perubahan
          _selectedChannel = deviceChannel;
        }

        // Update controllers dengan data aktual
        _emailController.text = _currentEmail;
        _ssidController.text = _currentSSID;
        _passwordController.text = _currentPassword;

        // Update delay values jika ada di config
        if (parts.length >= 12) {
          try {
            final delay1 = int.tryParse(parts[8]) ?? 500;
            final delay2 = int.tryParse(parts[9]) ?? 200;
            final delay3 = int.tryParse(parts[10]) ?? 100;
            final delay4 = int.tryParse(parts[11]) ?? 50;

            _speedControllers['LAMBAT']!.text = delay1.toString();
            _speedControllers['SEDANG']!.text = delay2.toString();
            _speedControllers['CEPAT']!.text = delay3.toString();
            _speedControllers['CEPAAT']!.text = delay4.toString();

            _speedValues['LAMBAT'] = delay1;
            _speedValues['SEDANG'] = delay2;
            _speedValues['CEPAT'] = delay3;
            _speedValues['CEPAAT'] = delay4;
          } catch (e) {
            print('Error parsing delay values: $e');
          }
        }
      });
    }
  }

    int _getMaxChannelsByLicense(int licenseLevel) {
      switch (licenseLevel) {
        case 1:
          return 8;
        case 2:
          return 16;
        case 3:
          return 32;
        case 4:
          return 64;
        case 5:
          return 80;
        default:
          return 0;
      }
    }

    void _updateChannel() {
    // Validasi license type
    final licenseLevel = int.tryParse(_licenseLevel) ?? 0;
    if (licenseLevel == 0) {
      _showSnackbar('Tidak dapat mengubah channel: Aktifkan lisensi terlebih dahulu');
      return;
    }

    // Validasi koneksi
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    if (_selectedChannel > 0 && _selectedChannel <= _maxChannels) {
      widget.socketService.setChannel(_selectedChannel);
      _showSnackbar('Mengubah channel ke: $_selectedChannel');
      
      // Update juga _deviceChannel untuk display
      setState(() {
        _deviceChannel = _selectedChannel.toString();
      });
    } else {
      _showSnackbar('Channel tidak valid untuk license level $_licenseLevel');
    }
  }

  Widget _buildChannelDropdown() {
    final licenseLevel = int.tryParse(_licenseLevel) ?? 0;
    final isLicenseValid = licenseLevel > 0;
    
    // Generate list channel berdasarkan max channels
    final availableChannels = List.generate(_maxChannels, (index) => index + 1);
    
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isLicenseValid ? AppColors.darkGrey : AppColors.darkGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLicenseValid ? AppColors.neonGreen : AppColors.darkGrey,
        ),
      ),
      child: DropdownButton<int>(
        value: _selectedChannel,
        isExpanded: true,
        dropdownColor: AppColors.darkGrey,
        style: TextStyle(
          color: isLicenseValid ? AppColors.pureWhite : AppColors.pureWhite.withOpacity(0.5),
          fontSize: 12,
        ),
        underline: const SizedBox(),
        icon: Icon(
          Icons.arrow_drop_down, 
          color: isLicenseValid ? AppColors.neonGreen : AppColors.darkGrey, 
          size: 20
        ),
        items: availableChannels.map((int channel) {
          return DropdownMenuItem<int>(
            value: channel,
            child: Text(
              '$channel',
              style: TextStyle(
                color: AppColors.pureWhite, 
                fontSize: 12
              ),
            ),
          );
        }).toList(),
        onChanged: isLicenseValid ? (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedChannel = newValue;
            });
          }
        } : null, // Disable jika license tidak aktif
      ),
    );
  }
    Widget _buildLicenseInfo() {
    final licenseLevel = int.tryParse(_licenseLevel) ?? 0;
    final isLicenseValid = licenseLevel > 0;
    
    String licenseInfo = '';
    String channelInfo = '';
    Color statusColor = AppColors.errorRed;
    
    if (!isLicenseValid) {
      licenseInfo = 'TIDAK AKTIF';
      channelInfo = 'Max 0 Channels - License tidak aktif';
      statusColor = AppColors.errorRed;
    } else {
      switch (licenseLevel) {
        case 1:
          licenseInfo = 'BASIC';
          channelInfo = 'Max 8 Channels';
          statusColor = Colors.blue;
          break;
        case 2:
          licenseInfo = 'STANDARD';
          channelInfo = 'Max 16 Channels';
          statusColor = Colors.green;
          break;
        case 3:
          licenseInfo = 'PRO';
          channelInfo = 'Max 32 Channels';
          statusColor = Colors.orange;
          break;
        case 4:
          licenseInfo = 'ENTERPRISE';
          channelInfo = 'Max 64 Channels';
          statusColor = Colors.purple;
          break;
        case 5:
          licenseInfo = 'ULTIMATE';
          channelInfo = 'Max 80 Channels';
          statusColor = Colors.red;
          break;
        default:
          licenseInfo = 'UNKNOWN';
          channelInfo = 'License tidak valid';
          statusColor = AppColors.errorRed;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLicenseValid ? AppColors.neonGreen.withOpacity(0.3) : AppColors.errorRed.withOpacity(0.3)
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Lisensi: $licenseInfo',
                  style: TextStyle(
                    color: isLicenseValid ? AppColors.neonGreen : AppColors.errorRed,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  channelInfo,
                  style: TextStyle(
                    color: isLicenseValid ? AppColors.pureWhite.withOpacity(0.7) : AppColors.errorRed.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                if (!isLicenseValid) ...[
                  const SizedBox(height: 6),
                  Text(
                    '• Channel terkunci sampai lisensi diaktifkan',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    '• Hubungi support untuk aktivasi lisensi',
                    style: TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isLicenseValid ? 'Level $_licenseLevel' : 'TIDAK AKTIF',
              style: TextStyle(
                color: AppColors.primaryBlack,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildChannelActionButton() {
    final licenseLevel = int.tryParse(_licenseLevel) ?? 0;
    final isLicenseValid = licenseLevel > 0;
    final isChannelValid = _selectedChannel > 0 && _selectedChannel <= _maxChannels;

    return _buildActionButton(
      text: isLicenseValid ? 'UBAH CHANNEL' : 'AKTIFKAN LISENSI TERLEBIH DAHULU',
      onPressed: isLicenseValid && isChannelValid ? _updateChannel : null,
      enabled: widget.socketService.isConnected && isLicenseValid && isChannelValid,
      backgroundColor: isLicenseValid ? AppColors.neonGreen : AppColors.darkGrey,
      foregroundColor: isLicenseValid ? AppColors.primaryBlack : AppColors.pureWhite.withOpacity(0.5),
    );
  }
    Color _getLicenseColor(String licenseLevel) {
      switch (licenseLevel) {
        case '1':
          return Colors.blue;
        case '2':
          return Colors.green;
        case '3':
          return Colors.orange;
        case '4':
          return Colors.purple;
        case '5':
          return Colors.red;
        default:
          return Colors.grey;
      }
    }

    void _updateSpeedSettings() {
      final delays = <int>[];
      var hasError = false;
      var errorMessage = '';

      for (final speed in _speedOptions) {
        final controller = _speedControllers[speed]!;
        final value = controller.text.trim();

        if (value.isEmpty) {
          hasError = true;
          errorMessage = 'Delay untuk $speed tidak boleh kosong';
          break;
        }

        final delay = int.tryParse(value);
        if (delay == null || delay <= 0) {
          hasError = true;
          errorMessage = 'Delay untuk $speed harus angka positif';
          break;
        }

        delays.add(delay);
      }

      if (hasError) {
        _showSnackbar(errorMessage);
        return;
      }

      if (delays.length == 4) {
        widget.socketService.setDelays(
          delays[0],
          delays[1],
          delays[2],
          delays[3],
        );

        _showSnackbar(
          'Speed settings applied: ${delays[0]}, ${delays[1]}, ${delays[2]}, ${delays[3]} ms',
        );

        if (mounted) {
          setState(() {
            _speedValues['LAMBAT'] = delays[0];
            _speedValues['SEDANG'] = delays[1];
            _speedValues['CEPAT'] = delays[2];
            _speedValues['CEPAAT'] = delays[3];
          });
        }
      }
    }

    void _handleSocketMessage(String message) {
      if (!mounted) return;

      if (message.startsWith('config,')) {
        _handleConfigResponse(message);
      } else if (message.startsWith('info,')) {
        final infoMessage = message.substring(5);
        _showSnackbar(infoMessage);
      } else if (message.startsWith('CONFIG_UPDATED:')) {
        // Ignore CONFIG_UPDATED messages to prevent setState after dispose
        print('Config updated received, ignoring...');
      }
    }

    void _updateEmail() {
      if (_emailController.text.isNotEmpty) {
        widget.socketService.setEmail(_emailController.text);
        _showSnackbar('Mengirim email: ${_emailController.text}');
      }
    }

  void _updateWelcomeSettings() {
    // Validasi index
    if (_selectedAnimationIndex < 0 || _selectedAnimationIndex >= _defaultAnimationsData.length) {
      _showSnackbar('Animasi tidak valid');
      return;
    }

    final deviceAnimationId = _selectedAnimationIndex + 1; // Convert to 1-based ID
    
    // Kirim ke device via socket
    widget.socketService.setWelcomeAnimation(deviceAnimationId, _selectedDuration);

    // Update config lokal
    setState(() {
      if (config != null) {
        config = config!.copyWith(
          animWelcome: _selectedAnimationIndex,
          durasiWelcome: _selectedDuration,
        );
      }
    });

    // Simpan ke preferences
    if (config != null) {
      _preferencesService.saveDeviceConfig(config!);
    }

    _showSnackbar(
      'Welcome animation diubah ke: ${_defaultAnimationsData[_selectedAnimationIndex]['name']} (ID: ${deviceAnimationId.toString().padLeft(2, '0')})',
    );
  }

    void _testWelcomeAnimation() {
      if (_selectedWelcomeAnimation == null) {
        _showSnackbar('Pilih animasi welcome terlebih dahulu');
        return;
      }

      final deviceAnimationId = _getDeviceAnimationId(_selectedWelcomeAnimation!);
      
      if (deviceAnimationId < 0 || deviceAnimationId > 31) {
        _showSnackbar('Animasi tidak valid');
        return;
      }

      widget.socketService.builtinAnimation(deviceAnimationId);

      _showSnackbar(
        'Testing animation: $_selectedWelcomeAnimation (ID: ${deviceAnimationId.toString().padLeft(2, '0')})',
      );

      print('🧪 Test Animation:');
      print('   - Animation Name: $_selectedWelcomeAnimation');
      print('   - Device ID: $deviceAnimationId');
    }

    void _updateWiFi() {
      if (_ssidController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty) {
        widget.socketService.setWifi(
          _ssidController.text,
          _passwordController.text,
        );
        _showSnackbar('WiFi config dikirim - Restarting device...');
      }
    }

    void _startCalibration() {
      if (!widget.socketService.isConnected) {
        _showSnackbar('Tidak terhubung ke device');
        return;
      }

      if (mounted) {
        setState(() {
          _isCalibrating = true;
          _currentCalibrationStep = 'A';
        });
      }

      widget.socketService.setCalibrationMode(true);
      _setupCalibrationListener();
      _showCalibrationPopup('A', 'Tekan tombol A pada remote');
    }

    void _setupCalibrationListener() {
      _calibrationSubscription?.cancel();

      _calibrationSubscription = widget.socketService.messages.listen((message) {
        if (!mounted) return;
        _handleCalibrationMessage(message);
      });
    }

    void _handleCalibrationMessage(String message) {
      print('Calibration message: $message');

      if (message.startsWith('remot,')) {
        final parts = message.split(',');
        if (parts.length >= 2) {
          final step = parts[1].trim();

          _closeCurrentPopup();

          if (step == '1' && _currentCalibrationStep == 'A') {
            if (mounted) {
              setState(() {
                _currentCalibrationStep = 'B';
              });
            }
            _showCalibrationPopup('B', 'Tekan tombol B pada remote');
          } else if (step == '2' && _currentCalibrationStep == 'B') {
            if (mounted) {
              setState(() {
                _currentCalibrationStep = 'C';
              });
            }
            _showCalibrationPopup('C', 'Tekan tombol C pada remote');
          } else if (step == '3' && _currentCalibrationStep == 'C') {
            if (mounted) {
              setState(() {
                _currentCalibrationStep = 'D';
              });
            }
            _showCalibrationPopup('D', 'Tekan tombol D pada remote');
          } else if (step == '4' && _currentCalibrationStep == 'D') {
            _finishCalibration();
          }
        }
      }
    }

    void _closeCurrentPopup() {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    void _showCalibrationPopup(String step, String instruction) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkGrey,
          title: Text(
            'KALIBRASI - STEP $step',
            style: TextStyle(
              color: AppColors.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.neonGreen, width: 3),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                instruction,
                style: TextStyle(color: AppColors.pureWhite, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Menunggu input dari remote...',
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.7),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            if (step == 'A')
              TextButton(
                onPressed: _cancelCalibration,
                child: Text('BATAL', style: TextStyle(color: AppColors.errorRed)),
              ),
          ],
        ),
      );
    }

    void _finishCalibration() {
      widget.socketService.send('KM0');
      Navigator.of(context).pop();

      if (mounted) {
        setState(() {
          _isCalibrating = false;
          _currentCalibrationStep = 'A';
        });
      }

      _showSnackbar('Kalibrasi berhasil diselesaikan!');
      _calibrationSubscription?.cancel();
      _calibrationSubscription = null;
    }

    void _cancelCalibration() {
      widget.socketService.send('KM0');
      Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        setState(() {
          _isCalibrating = false;
          _currentCalibrationStep = 'A';
        });
      }

      _showSnackbar('Kalibrasi dibatalkan');
      _calibrationSubscription?.cancel();
      _calibrationSubscription = null;
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
              child: const Text(
                'BATAL',
                style: TextStyle(color: AppColors.pureWhite),
              ),
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
              child: const Text(
                'RESET',
                style: TextStyle(color: AppColors.pureWhite),
              ),
            ),
          ],
        ),
      );
    }

    void _checkUpdate() {
      _showSnackbar('Checking for firmware updates...');
    }

    void _uploadFirmware() {
      _showSnackbar('Membuka firmware upload...');
    }

    void _contactSupport() {
      _showSnackbar('Membuka kontak support...');
    }

    Widget _buildWelcomeAnimationInfo() {
      if (_selectedWelcomeAnimation == null) return const SizedBox();

      final animationIndex = _getAnimationIndex(_selectedWelcomeAnimation!);
      if (animationIndex < 0 || animationIndex >= _defaultAnimationsData.length) {
        return const SizedBox();
      }

      final animationData = _defaultAnimationsData[animationIndex];
      final deviceId = _safeGetInt(animationData, 'deviceId');
      final channelCount = _safeGetInt(animationData, 'channelCount');
      final animationLength = _safeGetInt(animationData, 'animationLength');
      final delayData = _safeGetString(animationData, 'delayData');
      final description = _safeGetString(animationData, 'description');

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Animation:',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedWelcomeAnimation!,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'ID: ${deviceId.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (channelCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${channelCount} Channels',
                      style: TextStyle(color: AppColors.neonGreen, fontSize: 10),
                    ),
                  ),
                const SizedBox(width: 6),
                if (animationLength > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animationLength} Length',
                      style: TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
                const SizedBox(width: 6),
                if (delayData != '0')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${delayData}ms Delay',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSmallButton(
              'TEST ANIMASI',
              _testWelcomeAnimation,
              enabled: widget.socketService.isConnected,
            ),
          ],
        ),
      );
    }

    Widget _buildDurationDropdown() {
      return Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.darkGrey,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neonGreen),
        ),
        child: DropdownButton<int>(
          value: _selectedDuration,
          isExpanded: true,
          dropdownColor: AppColors.darkGrey,
          style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen, size: 20),
          items: _buildDurationItems(),
          onChanged: (int? newValue) {
            setState(() {
              _selectedDuration = newValue ?? 3;
            });
          },
        ),
      );
    }

    List<DropdownMenuItem<int>> _buildDurationItems() {
      return List.generate(10, (index) {
        final duration = index + 1;
        return DropdownMenuItem<int>(
          value: duration,
          child: Row(
            children: [
              Text(
                '$duration',
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
              ),
            ],
          ),
        );
      });
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

              _buildSection(
                title: 'Welcome mode',
                children: [
                  _buildSettingRow(
                    title: 'Animasi Welcome',
                    child: _buildWelcomeAnimationDropdown(),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    title: 'Durasi',
                    child: _buildDurationDropdown(),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedWelcomeAnimation != null)
                    _buildWelcomeAnimationInfo(),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    text: 'KIRIM',
                    onPressed: _updateWelcomeSettings,
                    enabled: widget.socketService.isConnected &&
                        _selectedWelcomeAnimation != null,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Di dalam build method, ganti section Firmware Info dengan:
  _buildSection(
    title: 'Versi Firmware : $_firmwareVersion',
    children: [
      // Tampilkan info license
      _buildLicenseInfo(),
      const SizedBox(height: 16),
      
      _buildInfoRow('Versi Aplikasi', '1.0.6'),
      _buildInfoRow('Device ID', _deviceId),
      _buildInfoRow('Level Lisensi', _licenseLevel),
      _buildInfoRow('Channel Saat Ini', _deviceChannel),
      
      // Hanya tampilkan dropdown channel jika license aktif
      if (_licenseLevel.isNotEmpty && int.tryParse(_licenseLevel)! > 0) ...[
        const SizedBox(height: 12),
        _buildSettingRow(
          title: 'Ubah Channel',
          child: _buildChannelDropdown(),
        ),
        const SizedBox(height: 16),
        _buildChannelActionButton(),
      ] else ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlack,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: AppColors.errorRed, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aktifkan lisensi untuk mengubah channel',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  ),
              const SizedBox(height: 24),

              _buildSection(
                title: 'Delay',
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Atur delay untuk setiap kecepatan (dalam milidetik)',
                    style: TextStyle(color: AppColors.pureWhite, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  _buildSpeedInputGrid(),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    text: 'APPLY SPEED SETTINGS',
                    onPressed: _updateSpeedSettings,
                    enabled: widget.socketService.isConnected,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'WIFI CONFIG',
                children: [
                  _buildConfigRow('SSID', _ssidController, false),
                  _buildConfigRow('PASSWORD', _passwordController, true),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    text: 'UBAH',
                    onPressed: _updateWiFi,
                    enabled: widget.socketService.isConnected,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'KALIBRASI',
                children: [
                  if (_isCalibrating) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlack,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.neonGreen),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: AppColors.neonGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sedang kalibrasi - Step $_currentCalibrationStep',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildActionButton(
                    text: _isCalibrating ? 'SEDANG KALIBRASI...' : 'MULAI',
                    onPressed: _isCalibrating ? null : _startCalibration,
                    enabled: widget.socketService.isConnected && !_isCalibrating,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'Sync',
                children: [
                  Center(
                    child: Container(
                      color: AppColors.altNeonGreen,
                      child: QrImageView(
                        data: [
                          config?.email ?? "-",
                          config?.mac ?? "-",
                          config?.jumlahChannel?.toString() ?? "-",
                        ].join(","),
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: AppColors.primaryBlack,
                        foregroundColor: AppColors.pureWhite,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              _buildSection(
                title: 'AKTIVASI',
                children: [
                  _buildSubSection(
                    title: 'User Lisensi',
                    children: [
                      _buildSerialRow(_serialController.text, 'COPY', 'BUY NOW'),
                      _buildPasteRow(
                        label: 'Kode Aktivasi',
                        rightButton: 'AKTIVASI',
                        onRightButton: _activateLicense,
                        controller: _activationController,
                        obscureText: true,
                        hintText: 'Paste kode aktivasi dari email...',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // _buildSection(
              //   title: 'MORE',
              //   children: [
              //     _buildSubSection(
              //       title: '',
              //       children: [
              //         _buildActionButton(
              //           text: 'RESET PABRIK',
              //           onPressed: _resetFactory,
              //           enabled: widget.socketService.isConnected,
              //           backgroundColor: AppColors.errorRed,
              //         ),
              //         const SizedBox(height: 12),
              //         _buildActionButton(
              //           text: 'CHECK UPDATE',
              //           onPressed: _checkUpdate,
              //         ),
              //         const SizedBox(height: 12),
              //         _buildActionButton(
              //           text: 'UPLOAD FIRMWARE',
              //           onPressed: _uploadFirmware,
              //         ),
              //       ],
              //     ),
              //     const SizedBox(height: 20),
              //     _buildActionButton(
              //       text: 'HUBUNGI KAMI',
              //       onPressed: _contactSupport,
              //       backgroundColor: AppColors.darkGrey,
              //       foregroundColor: AppColors.neonGreen,
              //     ),
              //   ],
              // ),
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
              Icon(Icons.warning_amber, color: AppColors.errorRed, size: 20),
          ],
        ),
      );
    }

    Widget _buildMiniPasteButton(Function() onPressed) {
      return Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: AppColors.neonGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
        ),
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(Icons.content_paste, size: 12, color: AppColors.neonGreen),
          tooltip: 'Paste dari clipboard',
        ),
      );
    }

    Widget _buildPasteRow({
      required String label,
      required String rightButton,
      required Function() onRightButton,
      TextEditingController? controller,
      bool obscureText = false,
      String? hintText,
    }) {
      // Controller default jika tidak disediakan
      final localController = controller ?? TextEditingController();

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Input Field dengan Tombol PASTE
            Row(
              children: [
                // Text Field
                Expanded(
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.neonGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: localController,
                            obscureText: obscureText,
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 12,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText:
                                  hintText ??
                                  'Klik PASTE untuk menyalin dari clipboard...',
                              hintStyle: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.5),
                                fontSize: 11,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        // Tombol Paste kecil di dalam field
                        if (localController.text.isEmpty)
                          _buildMiniPasteButton(() {
                            _pasteFromClipboard(localController);
                          }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Tombol PASTE Besar
                _buildSmallButton('PASTE', () {
                  _pasteFromClipboard(localController);
                }),

                const SizedBox(width: 4),

                // Tombol Aksi Kanan (AKTIVASI/UPDATE/etc)
                _buildSmallButton(
                  rightButton,
                  onRightButton,
                  enabled: widget.socketService.isConnected,
                ),
              ],
            ),

            // Preview teks yang sudah dipaste (jika ada)
            // if (localController.text.isNotEmpty) ...[
            //   const SizedBox(height: 6),
            //   Text(
            //     obscureText
            //         ? '●' * localController.text.length
            //         : 'Teks: ${localController.text}',
            //     style: TextStyle(
            //       color: AppColors.pureWhite.withOpacity(0.7),
            //       fontSize: 10,
            //       fontStyle: FontStyle.italic,
            //     ),
            //     maxLines: 1,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ],
          ],
        ),
      );
    }

    Widget _buildSection({
      required String title,
      required List<Widget> children,
    }) {
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

    Widget _buildTextField({
      required TextEditingController controller,
      required String hintText,
      bool readOnly = false,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TextStyle(color: AppColors.pureWhite.withOpacity(0.6)),
          ),
        ),
      );
    }

    Widget _buildActionButton({
      required String text,
      required void Function()? onPressed, // Ubah ke nullable
      bool enabled = true,
      Color? backgroundColor,
      Color? foregroundColor,
    }) {
      return SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null, // Ini sudah benar
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? AppColors.neonGreen,
            foregroundColor: foregroundColor ?? AppColors.primaryBlack,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: AppColors.darkGrey,
            disabledForegroundColor: AppColors.pureWhite.withOpacity(0.5),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
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

    Widget _buildConfigRow(
      String label,
      TextEditingController controller,
      bool readOnly,
    ) {
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
          _buildTextField(
            controller: controller,
            hintText: '',
            readOnly: readOnly,
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    Widget _buildSerialRow(
      String label,
      String leftButton,
      String rightButton, {
      Function()? onActivate,
    }) {
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
                style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            _buildSmallButton(leftButton, () {
              _copyToClipboard(label, '$leftButton: $label');
            }),
            const SizedBox(width: 4),
            _buildSmallButton(
              rightButton,
              onActivate ??
                  () {
                    _showSnackbar('$rightButton: $label');
                  },
              enabled: widget.socketService.isConnected || onActivate == null,
            ),
          ],
        ),
      );
    }

    Widget _buildSmallButton(
      String text,
      Function() onPressed, {
      bool enabled = true,
    }) {
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

    @override
    void dispose() {
      print('🛑 SettingsPage disposing...');
      
      // --- PERBAIKAN: Cancel semua stream subscriptions ---
      _messageSubscription?.cancel();
      _calibrationSubscription?.cancel();
      
      _messageSubscription = null;
      _calibrationSubscription = null;

      _emailController.dispose();
      _ssidController.dispose();
      _passwordController.dispose();
      _serialController.dispose();
      _activationController.dispose();
      _mitraIdController.dispose();

      for (final controller in _speedControllers.values) {
        controller.dispose();
      }

      super.dispose();
      print('✅ SettingsPage disposed');
    }
  }
