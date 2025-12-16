import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/pages/map_editor_modal.dart';
import 'package:iTen/services/config_service.dart';
import 'package:iTen/services/firebase_data_service.dart';
import 'package:iTen/services/preferences_service.dart';
import 'package:iTen/services/socket_service.dart';

class TriggerPage extends StatefulWidget {
  final SocketService socketService;

  const TriggerPage({super.key, required this.socketService});

  @override
  State<TriggerPage> createState() => _TriggerPageState();
}

class _TriggerPageState extends State<TriggerPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final ConfigService _configService = ConfigService();
  final PreferencesService _preferencesService = PreferencesService();

  // Dropdown values untuk setiap trigger
  String? _selectedQuick;
  String? _selectedLowBeam;
  String? _selectedHighBeam;
  String? _selectedFogLamp;

  // Data dari My File
  List<AnimationModel> _userAnimations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  ConfigModel? _deviceConfig;
  bool _isLoadingConfig = false;
  @override
  void initState() {
    super.initState();
    _loadUserAnimations();
    _loadSavedTriggerSettings();
    _loadDeviceConfig();
  }

  Future<void> _loadDeviceConfig() async {
    try {
      setState(() {
        _isLoadingConfig = true;
      });

      final config = await _preferencesService.getDeviceConfig();

      if (config != null) {
        setState(() {
          _deviceConfig = config;
        });

        // Update trigger settings berdasarkan konfigurasi device
        _updateTriggerSettingsFromConfig(config);

        print('✅ Loaded device config: ${config.summary}');
        print('🎯 Trigger Data from Device:');
        print('   - Trigger1: ${config.trigger1Data}');
        print('   - Trigger2: ${config.trigger2Data}');
        print('   - Trigger3: ${config.trigger3Data}');
      }
    } catch (e) {
      print('❌ Error loading device config: $e');
    } finally {
      setState(() {
        _isLoadingConfig = false;
      });
    }
  }

  // Update trigger settings berdasarkan konfigurasi device - PERBAIKI
  // Update trigger settings berdasarkan konfigurasi device - PERBAIKI
void _updateTriggerSettingsFromConfig(ConfigModel config) {
    print('🔄 Updating trigger settings from config...');

    // Debug mode values
    print('  - Quick Trigger Mode: ${config.quickTrigger}');
    print(
      '  - Trigger1 Mode: ${config.trigger1Mode} (${config.trigger1Mode == 1 ? 'KEDIP' : 'STATIS'})',
    );
    print(
      '  - Trigger2 Mode: ${config.trigger2Mode} (${config.trigger2Mode == 1 ? 'KEDIP' : 'STATIS'})',
    );
    print(
      '  - Trigger3 Mode: ${config.trigger3Mode} (${config.trigger3Mode == 1 ? 'KEDIP' : 'STATIS'})',
    );

    setState(() {
      // Konversi trigger mode ke string representation
      _selectedQuick = _convertTriggerModeToString(config.quickTrigger);

      // --- LOGIC PERBAIKAN: 1 = DINAMIS (KEDIP) ---
      _selectedLowBeam = config.trigger1Mode == 1
          ? 'MAP DINAMIS' // Jika 1, itu DINAMIS/KEDIP
          : 'MAP STATIS'; // Jika 0, itu STATIS
      _selectedHighBeam = config.trigger2Mode == 1
          ? 'MAP DINAMIS'
          : 'MAP STATIS';
      _selectedFogLamp = config.trigger3Mode == 1
          ? 'MAP DINAMIS'
          : 'MAP STATIS';
    });

    _saveTriggerSettings();
}

  // Konversi trigger mode integer ke string
  String _convertTriggerModeToString(int mode) {
    switch (mode) {
      case 0:
        return 'MATI';
      case 1:
        return 'REMOTE A';
      case 2:
        return 'REMOTE B';
      case 3:
        return 'REMOTE C';
      case 4:
        return 'REMOTE D';
      default:
        return 'MATI';
    }
  }

  // Handler untuk kirim data dengan fallback protection
  void _sendTriggerWithFallback(String triggerType, String? setting) {
    if (setting == null || !widget.socketService.isConnected) return;

    try {
      final triggerIndex = _getTriggerIndex(triggerType);
      final safeTriggerIndex = triggerIndex != -1
          ? triggerIndex
          : 1; // Fallback ke index 1

      // Validasi setting value
      final validSettings = [
        'MATI',
        'REMOTE A',
        'REMOTE B',
        'REMOTE C',
        'REMOTE D',
      ];
      final safeSetting = validSettings.contains(setting)
          ? setting
          : 'REMOTE A'; // Fallback ke REMOTE A

      // final modeCode = _getModeCode(safeSetting);
      widget.socketService.send('SQ0');

      print(
        '✅ Sent $triggerType trigger (index: $safeTriggerIndex): $safeSetting',
      );
    } catch (e) {
      // Fallback ke default command jika error
      widget.socketService.send('S1RA');
      print('🔄 Fallback to default trigger due to error: $e');
    }
  }

  // Enhanced method untuk kirim trigger settings dengan fallback
  Future<void> _sendTriggerSettingsWithFallback() async {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    try {
      print('🔄 Mengirim trigger settings dengan fallback protection...');

      // Kirim dengan fallback untuk setiap trigger
      await _sendSingleTriggerWithFallback('QUICK', _selectedQuick);
      await _sendSingleTriggerWithFallback('LOW', _selectedLowBeam);
      await _sendSingleTriggerWithFallback('HIGH', _selectedHighBeam);
      await _sendSingleTriggerWithFallback('FOG', _selectedFogLamp);

      _showSnackbar(
        'Trigger settings berhasil dikirim dengan fallback protection!',
      );
    } catch (e) {
      // Ultimate fallback - kirim default command
      widget.socketService.send('S1RA');
      _showSnackbar('Menggunakan default trigger settings', isError: false);
      print('🔄 Ultimate fallback applied due to error: $e');
    }
  }

  // Method untuk kirim single trigger dengan fallback
  Future<void> _sendSingleTriggerWithFallback(
    String triggerType,
    String? setting,
  ) async {
    if (setting == null || setting == 'MATI') return;

    final triggerIndex = _getTriggerIndex(triggerType);
    final safeTriggerIndex = triggerIndex != -1
        ? triggerIndex
        : 1; // Fallback ke index 1

    // Jika custom animation tidak ditemukan, fallback ke REMOTE A
    if (_isCustomAnimation(setting)) {
      final animation = _userAnimations.firstWhere(
        (anim) => anim.name == setting,
        orElse: () => AnimationModel(
          name: '',
          channelCount: 0,
          animationLength: 0,
          description: '',
          delayData: '',
          frameData: [],
        ),
      );

      if (animation.name.isEmpty) {
        // Fallback ke REMOTE A jika custom animation tidak ditemukan
        widget.socketService.send('S${safeTriggerIndex}RA');
        print(
          '🔄 Fallback to REMOTE A for $triggerType (custom animation not found)',
        );
        return;
      }
    }

    // Kirim setting normal
    final triggerConfig = _getTriggerConfig(triggerType, setting);
    if (triggerConfig != null) {
      await _sendTriggerData(triggerConfig);
    }
  }

  // Handler untuk reset dengan fallback values
  void _resetTriggerSettingsWithFallback() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    setState(() {
      // Reset ke values yang aman (index 1 dari available options)
      _selectedQuick = 'REMOTE A'; // Fallback ke index 1
      _selectedLowBeam = 'MAP STATIS'; // Fallback ke index 1
      _selectedHighBeam = 'MAP STATIS'; // Fallback ke index 1
      _selectedFogLamp = 'MAP STATIS'; // Fallback ke index 1
    });

    _saveTriggerSettings();

    // Kirim default fallback settings ke device
    widget.socketService.send('S1RA'); // QUICK -> REMOTE A
    widget.socketService.send('S2MS'); // LOW BEAM -> MAP STATIS

    _showSnackbar('Trigger settings direset ke default fallback!');
  }

  // Validator untuk dropdown value dengan fallback
  String? _validateDropdownValue(String? value, List<String> options) {
    if (value == null) return options.isNotEmpty ? options[1] : null;
    return options.contains(value) ? value : options[1]; // Fallback ke index 1
  }

  // Handler untuk onChanged dengan fallback
  void _onTriggerChanged(
    String? newValue,
    Function(String?) onChanged,
    List<String> availableOptions,
  ) {
    final safeValue = _validateDropdownValue(newValue, availableOptions);
    onChanged(safeValue);
  }

  void _sendQuickSettingWithFallback(String triggerLabel, String? value) {
    final safeValue = _validateDropdownValue(value, [
      "MATI",
      "REMOTE A",
      "REMOTE B",
      "REMOTE C",
      "REMOTE D",
    ]);

    _sendTriggerWithFallback(triggerLabel, safeValue);
  }

  // Load animasi dari user selections di preferences
  Future<void> _loadUserAnimations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final userAnimations = await _firebaseService.getUserSelectedAnimations();

      setState(() {
        _userAnimations = userAnimations;
        _isLoading = false;
      });

      print('✅ Loaded ${_userAnimations.length} animations for triggers');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading animations: $e';
        _isLoading = false;
      });
      print('❌ Error loading animations for triggers: $e');
    }
  }

  // Load saved trigger settings dari preferences
  Future<void> _loadSavedTriggerSettings() async {
    try {
      final settings =
          await _firebaseService.getUserSetting('trigger_settings')
              as Map<String, dynamic>?;

      if (settings != null) {
        setState(() {
          _selectedQuick = settings['quick'];
          _selectedLowBeam = settings['low_beam'];
          _selectedHighBeam = settings['high_beam'];
          _selectedFogLamp = settings['fog_lamp'];
        });

        print('✅ Loaded saved trigger settings from preferences');
      }
    } catch (e) {
      print('❌ Error loading saved trigger settings: $e');
    }
  }

  // Save trigger settings ke preferences
  Future<void> _saveTriggerSettings() async {
    try {
      final settings = {
        'quick': _selectedQuick,
        'low_beam': _selectedLowBeam,
        'high_beam': _selectedHighBeam,
        'fog_lamp': _selectedFogLamp,
        'last_updated': DateTime.now().toIso8601String(),
      };

      await _firebaseService.saveUserSetting('trigger_settings', settings);
      print('💾 Saved trigger settings to preferences');
    } catch (e) {
      print('❌ Error saving trigger settings: $e');
    }
  }

  // ========== SOCKET ACTIONS ==========

  // Kirim trigger settings ke device
  Future<void> _sendTriggerSettings() async {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    // Validasi minimal satu trigger dipilih
    final selectedTriggers = [
      _selectedQuick,
      _selectedLowBeam,
      _selectedHighBeam,
      _selectedFogLamp,
    ].where((trigger) => trigger != null && trigger != 'MATI').toList();

    if (selectedTriggers.isEmpty) {
      _showSnackbar('Pilih minimal satu trigger mode!', isError: true);
      return;
    }

    try {
      print('🔄 Mengirim trigger settings ke device...');

      // Kirim setting untuk setiap trigger
      await _sendTriggerSetting('QUICK', _selectedQuick);
      await _sendTriggerSetting('LOW', _selectedLowBeam);
      await _sendTriggerSetting('HIGH', _selectedHighBeam);
      await _sendTriggerSetting('FOG', _selectedFogLamp);

      // Simpan setting terakhir yang dikirim
      await _firebaseService.saveUserSetting('last_sent_triggers', {
        'quick': _selectedQuick,
        'low_beam': _selectedLowBeam,
        'high_beam': _selectedHighBeam,
        'fog_lamp': _selectedFogLamp,
        'sent_at': DateTime.now().toIso8601String(),
      });

      _showSnackbar(
        '${selectedTriggers.length} trigger settings berhasil dikirim ke device!',
      );
    } catch (e) {
      _showSnackbar('Error mengirim trigger settings: $e', isError: true);
      print('❌ Error sending trigger settings: $e');
    }
  }

  // Kirim setting untuk trigger tertentu
  Future<void> _sendTriggerSetting(String triggerType, String? setting) async {
    if (setting == null || setting == 'MATI') return;

    print('📤 Sending $triggerType trigger: $setting');

    // Map trigger type ke socket command
    final triggerConfig = _getTriggerConfig(triggerType, setting);
    if (triggerConfig != null) {
      // Kirim data trigger sesuai type
      await _sendTriggerData(triggerConfig);
    }
  }

  // Get trigger configuration berdasarkan type dan setting
  Map<String, dynamic>? _getTriggerConfig(String triggerType, String setting) {
    final triggerIndex = _getTriggerIndex(triggerType);
    if (triggerIndex == -1) return null;

    // Cek jika setting adalah animasi custom dari My File
    if (_isCustomAnimation(setting)) {
      final animation = _userAnimations.firstWhere(
        (anim) => anim.name == setting,
        orElse: () => AnimationModel(
          name: '',
          channelCount: 0,
          animationLength: 0,
          description: '',
          delayData: '',
          frameData: [],
        ),
      );

      if (animation.name.isNotEmpty) {
        return {
          'type': 'ANIMASI_CUSTOM',
          'trigger_index': triggerIndex,
          'animation_name': animation.name,
          'channel_count': animation.channelCount,
          'frame_data': animation.frameData,
          'delay_data': animation.delayData,
        };
      }
    }

    // Untuk built-in modes
    return {'type': setting, 'trigger_index': triggerIndex};
  }

  // Kirim data trigger ke device via socket
  Future<void> _sendTriggerData(Map<String, dynamic> config) async {
    final triggerIndex = config['trigger_index'] as int;
    final type = config['type'] as String;

    if (type == 'ANIMASI_CUSTOM') {
      // Kirim animasi custom
      final animationName = config['animation_name'] as String;
      final channelCount = config['channel_count'] as int;
      final frameData = config['frame_data'] as List<String>;
      final delayData = config['delay_data'] as String;

      // Kirim sebagai trigger data (format khusus untuk trigger)
      _sendCustomAnimationTrigger(
        triggerIndex,
        animationName,
        channelCount,
        frameData,
        delayData,
      );
    } else {
      // Kirim built-in mode
      _sendBuiltInTrigger(triggerIndex, type);
    }
  }

  // Kirim animasi custom untuk trigger
  void _sendCustomAnimationTrigger(
    int triggerIndex,
    String animationName,
    int channelCount,
    List<String> frameData,
    String delayData,
  ) {
    // Format: S[trigger_index][animation_data]
    // Contoh: S1 untuk QUICK, S2 untuk LOW, S3 untuk HIGH, S4 untuk FOG

    // Kirim frame data
    for (int i = 0; i < frameData.length; i++) {
      final frame = frameData[i];
      if (frame.isNotEmpty) {
        // Kirim per frame (bisa disesuaikan dengan protocol device)
        widget.socketService.send('S$triggerIndex${_pad3(i + 1)}$frame');
      }
    }

    // Kirim delay data jika ada
    if (delayData.isNotEmpty) {
      widget.socketService.send('S${triggerIndex}D$delayData');
    }

    print('✅ Sent custom animation "$animationName" for trigger $triggerIndex');
  }

  // Kirim built-in trigger mode
  void _sendBuiltInTrigger(int triggerIndex, String mode) {
    final modeCode = _getModeCode(mode);
    widget.socketService.send('S$triggerIndex$modeCode');
    print('✅ Sent built-in mode "$mode" for trigger $triggerIndex');
  }

  // Helper methods
  int _getTriggerIndex(String triggerType) {
    print("triggerType is $triggerType");
    switch (triggerType) {
      case 'MATI':
        return 0;
      case 'REMOTE A':
        return 1;
      case 'REMOTE B':
        return 2;
      case 'REMOTE C':
        return 3;
      case 'REMOTE D':
        return 4;
      default:
        return 1;
    }
  }

  bool _isCustomAnimation(String? setting) {
    if (setting == null) return false;
    return _userAnimations.any((anim) => anim.name == setting);
  }

  String _pad3(int number) => number.toString().padLeft(3, '0');

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.orange : AppColors.neonGreen,
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Method untuk membuka modal editor MAP dengan data dari device
  // Di dalam TriggerPage - pastikan mapping yang benar
  void _openMapEditor(String triggerLabel) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    // PERBAIKAN: Debug log untuk verifikasi
    print('🔧 Opening MAP Editor with current device config:');
    print('   - Trigger Label: $triggerLabel');
    print('   - Device Config: ${_deviceConfig?.summary}');

    if (_deviceConfig != null) {
      print('   - Available Trigger Data:');
      print('     * LOW BEAM (Trigger1): ${_deviceConfig!.trigger1Data}');
      print('     * HIGH BEAM (Trigger2): ${_deviceConfig!.trigger2Data}');
      print('     * FOG LAMP (Trigger3): ${_deviceConfig!.trigger3Data}');
    }

    MapEditorModal.show(
      context: context,
      triggerLabel: triggerLabel,
      socketService: widget.socketService,
      configData: _deviceConfig,
      onMapDataCreated: (mapData) {
        _sendMapDataToDevice(triggerLabel, mapData);
        _updateLocalConfigWithMapData(triggerLabel, mapData);
      },
    );
  }

  // Update config lokal dengan data MAP baru
  void _updateLocalConfigWithMapData(String triggerLabel, List<int> mapData) {
    if (_deviceConfig == null) return;

    setState(() {
      _deviceConfig = _deviceConfig!.copyWith(
        trigger1Data: triggerLabel == 'LOW BEAM'
            ? mapData
            : _deviceConfig!.trigger1Data,
        trigger2Data: triggerLabel == 'HIGH BEAM'
            ? mapData
            : _deviceConfig!.trigger2Data,
        trigger3Data: triggerLabel == 'FOG LAMP'
            ? mapData
            : _deviceConfig!.trigger3Data,
      );
    });

    print('🔄 Updated local config for $triggerLabel: $mapData');
  }
// Method baru untuk handle toggle changes dari UI - PERBAIKI
// Method baru untuk handle toggle changes dari UI - PERBAIKI
void _handleMapToggleChange(String triggerLabel, bool isDynamic) {
  // Catatan: isDynamic = true jika switch di KANAN (KEDIP/DINAMIS = 1)
 print('🎯 Toggle clicked: $triggerLabel -> ${isDynamic ? 1 : 0}');
 
 if (!widget.socketService.isConnected) {
  print('❌ Not connected, toggle ignored');
  return;
 }

 try {
  print('🔄 Handling MAP toggle change for $triggerLabel: ${isDynamic ? 1 : 0}');
  
  // Nilai yang dikirim: isDynamic ? 1 : 0
  final modeValue = isDynamic ? 1 : 0; 

  // Update device config dengan nilai baru
  if (_deviceConfig != null) {
   setState(() {
    _deviceConfig = _deviceConfig!.copyWith(
     trigger1Mode: triggerLabel == 'LOW BEAM' 
       ? modeValue 
       : _deviceConfig!.trigger1Mode,
     trigger2Mode: triggerLabel == 'HIGH BEAM' 
       ? modeValue 
       : _deviceConfig!.trigger2Mode,
     trigger3Mode: triggerLabel == 'FOG LAMP' 
       ? modeValue 
       : _deviceConfig!.trigger3Mode,
    );
   });
   
   print('📊 Updated device config:');
   print('  - Trigger1 Mode: ${_deviceConfig!.trigger1Mode}');
   print('  - Trigger2 Mode: ${_deviceConfig!.trigger2Mode}');
   print('  - Trigger3 Mode: ${_deviceConfig!.trigger3Mode}');
  }

  // Update local state untuk UI
  setState(() {
   switch (triggerLabel) {
    case 'LOW BEAM':
     _selectedLowBeam = isDynamic ? 'MAP DINAMIS' : 'MAP STATIS'; // Perbaikan Label
     break;
    case 'HIGH BEAM':
     _selectedHighBeam = isDynamic ? 'MAP DINAMIS' : 'MAP STATIS'; // Perbaikan Label
     break;
    case 'FOG LAMP':
     _selectedFogLamp = isDynamic ? 'MAP DINAMIS' : 'MAP STATIS'; // Perbaikan Label
     break;
   }
  });

  // Save settings
  _saveTriggerSettings();

  // Send to device
  // Karena 1=DINAMIS/KEDIP, kita kirim MD (Dynamic) jika true
  final isStatic = !isDynamic; // 0 = STATIS
  _sendMapToggleCommand(triggerLabel, isStatic); // Perlu dibalik di sini!

  print('✅ Toggle change completed successfully');

 } catch (e) {
  print('❌ Error handling MAP toggle change: $e');
 }
}
Future<void> _saveDeviceConfig() async {
  if (_deviceConfig == null) return;
  
  try {
    await _preferencesService.saveDeviceConfig(_deviceConfig!);
    print('💾 Saved device config to preferences');
  } catch (e) {
    print('❌ Error saving device config: $e');
  }
}

  // Method untuk mengirim data MAP ke device
  void _sendMapDataToDevice(String triggerLabel, List<int> mapData) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    try {
      // Konversi trigger label ke trigger number
      final triggerNum = _getTriggerNumber(triggerLabel);

      // Kirim data MAP menggunakan socket service
      widget.socketService.setTrigger(triggerNum, mapData);

      _showSnackbar('Data MAP untuk $triggerLabel berhasil dikirim ke device!');

      print('📤 Sent MAP data for $triggerLabel: $mapData');
    } catch (e) {
      _showSnackbar('Error mengirim data MAP: $e', isError: true);
      print('❌ Error sending MAP data: $e');
    }
  }

  // Helper method untuk konversi trigger label ke number
  int _getTriggerNumber(String triggerLabel) {
    switch (triggerLabel) {
      case 'QUICK':
        return 0;
      case 'LOW BEAM':
        return 1;
      case 'HIGH BEAM':
        return 2;
      case 'FOG LAMP':
        return 3;
      default:
        return 0;
    }
  }

  // Di TriggerPage - tambahkan method untuk kirim semua settings
  Future<void> _sendAllTriggerSettings() async {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    try {
      print('🔄 Mengirim semua trigger settings...');

      // Kirim QUICK setting (jika ada)
      if (_selectedQuick != null && _selectedQuick != 'MATI') {
        _sendQuickSetting('QUICK', _selectedQuick);
      }

      // Kirim MAP toggle settings
      _sendMapToggleIfActive('LOW BEAM', _selectedLowBeam);
      _sendMapToggleIfActive('HIGH BEAM', _selectedHighBeam);
      _sendMapToggleIfActive('FOG LAMP', _selectedFogLamp);

      _showSnackbar('Semua trigger settings berhasil dikirim!');
    } catch (e) {
      _showSnackbar('Error mengirim trigger settings: $e', isError: true);
      print('❌ Error sending all trigger settings: $e');
    }
  }

  // Method untuk kirim MAP toggle jika aktif
  // Method untuk kirim MAP toggle jika aktif - PERBAIKI
  void _sendMapToggleIfActive(String triggerLabel, String? setting) {
    // Jika setting adalah mode MAP, kirim toggle berdasarkan current state
    if (setting == 'MAP STATIS' || setting == 'MAP DINAMIS') {
      // Dapatkan current state dari device config
      int currentState = 0; // default KEDIP (0)

      switch (triggerLabel) {
        case 'LOW BEAM':
          currentState = _deviceConfig?.trigger1Mode ?? 0;
          break;
        case 'HIGH BEAM':
          currentState = _deviceConfig?.trigger2Mode ?? 0;
          break;
        case 'FOG LAMP':
          currentState = _deviceConfig?.trigger3Mode ?? 0;
          break;
      }

      // Konversi ke boolean: 1 = STATIS, 0 = KEDIP
      final isStatic = currentState == 1;
      _sendMapToggleCommand(triggerLabel, isStatic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = widget.socketService.isConnected;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Connection Status
              // _buildConnectionStatus(),
              const SizedBox(height: 16),

              // Warning jika tidak terkoneksi
              // if (!isConnected) _buildDisconnectedWarning(),

              // Container untuk 4 settingan trigger
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonGreen),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trigger Settings',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Statistics
                    // if (_userAnimations.isNotEmpty)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 8.0),
                    //     child: Text(
                    //       '${_userAnimations.length} custom animations available',
                    //       style: TextStyle(
                    //         color: AppColors.pureWhite.withOpacity(0.7),
                    //         fontSize: 12,
                    //       ),
                    //     ),
                    //   ),

                    // const SizedBox(height: 16),

                    // Loading Indicator
                    if (_isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.neonGreen,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Loading animations...',
                              style: TextStyle(color: AppColors.pureWhite),
                            ),
                          ],
                        ),
                      )
                    // Error Message
                    else if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              onPressed: _loadUserAnimations,
                              icon: Icon(Icons.refresh, color: Colors.red),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      )
                    // Trigger Settings
                    else ...[
                      // Setting QUICK
                      _buildQuickItem(
                        label: 'CALL',
                        selectedValue: _selectedQuick,
                        onChanged: (value) {
                          if (!isConnected) return;

                          final safeValue = _validateDropdownValue(value, [
                            "MATI",
                            "REMOTE A",
                            "REMOTE B",
                            "REMOTE C",
                            "REMOTE D",
                          ]);

                          setState(() {
                            _selectedQuick = safeValue;
                          });
                          _saveTriggerSettings();

                          // Kirim langsung ke device
                          // _sendQuickSettingWithFallback('QUICK', safeValue);
                        },
                      ),

                      // Di build method - pastikan passing value yang benar
                      // Di build method - PERBAIKI dengan menghapus onChanged yang redundant
                      _buildTriggerItem(
                        label: 'LOW BEAM',
                        selectedValue: _selectedLowBeam,
                        value: _deviceConfig?.trigger1Mode ?? 0, // 1 atau 0
                        onChanged: (value) {
                          // Ini untuk dropdown (jika ada), tapi untuk toggle kita gunakan handleMapToggleChange
                          if (!isConnected) return;
                          setState(() {
                            _selectedLowBeam = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),

                      _buildTriggerItem(
                        label: 'HIGH BEAM',
                        selectedValue: _selectedHighBeam,
                        value: _deviceConfig?.trigger2Mode ?? 0, // 1 atau 0
                        onChanged: (value) {
                          if (!isConnected) return;
                          setState(() {
                            _selectedHighBeam = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),

                      _buildTriggerItem(
                        label: 'FOG LAMP',
                        selectedValue: _selectedFogLamp,
                        value: _deviceConfig?.trigger3Mode ?? 0, // 1 atau 0
                        onChanged: (value) {
                          if (!isConnected) return;
                          setState(() {
                            _selectedFogLamp = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tombol KIRIM KE DEVICE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (isConnected && !_isLoading)
                      ? _sendTriggerSettings
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isConnected && !_isLoading)
                        ? AppColors.neonGreen
                        : AppColors.neonGreen.withOpacity(0.3),
                    foregroundColor: AppColors.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isConnected ? 'KIRIM KE DEVICE' : 'DISCONNECTED',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? AppColors.primaryBlack
                          : AppColors.primaryBlack.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tombol RESET
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: isConnected ? _resetTriggerSettings : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isConnected
                        ? AppColors.neonGreen
                        : AppColors.neonGreen.withOpacity(0.3),
                    side: BorderSide(
                      color: isConnected
                          ? AppColors.neonGreen
                          : AppColors.neonGreen.withOpacity(0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'RESET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? AppColors.neonGreen
                          : AppColors.neonGreen.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // Info Panel
              // if (_userAnimations.isNotEmpty) ...[
              //   const SizedBox(height: 16),
              //   Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: AppColors.darkGrey,
              //       borderRadius: BorderRadius.circular(8),
              //       border: Border.all(
              //         color: AppColors.neonGreen.withOpacity(0.3),
              //       ),
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         Text(
              //           'Trigger Summary',
              //           style: TextStyle(
              //             color: AppColors.neonGreen,
              //             fontWeight: FontWeight.bold,
              //           ),
              //         ),
              //         const SizedBox(height: 8),

              //         _buildTriggerInfo('LOW BEAM', _selectedLowBeam),
              //         _buildTriggerInfo('HIGH BEAM', _selectedHighBeam),
              //         _buildTriggerInfo('FOG LAMP', _selectedFogLamp),
              //         const SizedBox(height: 8),
              //         Divider(color: AppColors.neonGreen.withOpacity(0.3)),
              //         _buildConnectionInfo(),
              //       ],
              //     ),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildTriggerItem({
  required String label,
  required String? selectedValue,
  required Function(String?) onChanged,
  required int value // value sekarang adalah 1 atau 0 (1 = KEDIP, 0 = STATIS)
}) {
  // PENTING: Gunakan isDynamic untuk merepresentasikan logika 1 = KEDIP
  final isConnected = widget.socketService.isConnected;

  // Konversi nilai 1/0 ke boolean untuk Switch: TRUE jika KEDIP (1)
  bool isDynamic = value == 1;

  // DEBUG: Print current value
  print('🔧 Building $label - Value: $value, isDynamic: $isDynamic');

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryBlack,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isConnected
            ? AppColors.neonGreen.withOpacity(0.5)
            : AppColors.neonGreen.withOpacity(0.2),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Baris pertama: Label
        Row(
          children: [
            // Label trigger
            Expanded(
              child: Text(
                // Label sekarang mengikuti state data yang benar (1=KEDIP, 0=STATIS)
                '$label (${isDynamic ? 'KEDIP' : 'STATIS'})', 
                style: TextStyle(
                  color: isConnected
                      ? AppColors.pureWhite
                      : AppColors.pureWhite.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Baris kedua: Tombol MAP dan Toggle
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Tombol MAP - Bisa diklik untuk buka editor
              Expanded(
                child: GestureDetector(
                  onTap: isConnected ? () => _openMapEditor(label) : null,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppColors.neonGreen
                          : AppColors.neonGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        'MAP',
                        style: TextStyle(
                          color: isConnected
                              ? AppColors.primaryBlack
                              : AppColors.primaryBlack.withOpacity(0.5),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Label STATIS (Kiri)
              Text(
                'STATIS',
                style: TextStyle(
                  // STATIS aktif jika BUKAN isDynamic
                  color: !isDynamic
                      ? (isConnected
                              ? AppColors.neonGreen
                              : AppColors.neonGreen.withOpacity(0.3))
                      : AppColors.pureWhite.withOpacity(
                            isConnected ? 0.5 : 0.3,
                          ),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(width: 8),

              // Toggle Switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  // Value Switch: ON jika isDynamic (KEDIP/1)
                  value: isDynamic,
                  activeColor: isConnected
                      ? AppColors.neonGreen
                      : AppColors.neonGreen.withOpacity(0.3),
                  activeTrackColor: isConnected
                      ? AppColors.neonGreen.withOpacity(0.3)
                      : AppColors.neonGreen.withOpacity(0.1),
                  inactiveThumbColor: isConnected
                      ? AppColors.pureWhite
                      : AppColors.pureWhite.withOpacity(0.3),
                  inactiveTrackColor: isConnected
                      ? AppColors.pureWhite.withOpacity(0.3)
                      : AppColors.pureWhite.withOpacity(0.1),
                  onChanged: isConnected
                      ? (newValue) {
                          print('🎯 Switch $label clicked: $newValue');
                          // newValue (boolean) mewakili status BARU: TRUE jika KEDIP (1)
                          // Panggil _handleMapToggleChange dengan status DINAMIS BARU
                          _handleMapToggleChange(label, newValue); 
                        }
                      : null,
                ),
              ),

              const SizedBox(width: 8),

              // Label KEDIP (Kanan)
              Text(
                'KEDIP',
                style: TextStyle(
                  // KEDIP aktif jika isDynamic
                  color: isDynamic
                      ? (isConnected
                              ? AppColors.neonGreen
                              : AppColors.neonGreen.withOpacity(0.3))
                      : AppColors.pureWhite.withOpacity(
                            isConnected ? 0.5 : 0.3,
                          ),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Status info
        const SizedBox(height: 8),
        Text(
          // Status Mode: Disesuaikan dengan isDynamic
          isDynamic ? 'Mode: KEDIP (1)' : 'Mode: STATIS (0)',
          style: TextStyle(
            color: AppColors.neonGreen.withOpacity(isConnected ? 0.7 : 0.3),
            fontSize: 11,
          ),
        ),
        
        // Debug info
        Text(
          'Current Value: $value',
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}
  // Method untuk kirim toggle command dengan nilai 1/0
  void _sendMapToggleCommand(String triggerLabel, bool isStatic) {
    if (!widget.socketService.isConnected) return;

    try {
      final triggerCode = _getMapToggleCode(triggerLabel);
      final value = isStatic ? 0 : 1; // Convert boolean ke 1/0

      widget.socketService.sendTriggerToggle(triggerCode, value);

      print('🔘 Sent MAP toggle: $triggerCode$value');
      _showSnackbar('$triggerLabel: ${isStatic ? 'STATIS (1)' : 'KEDIP (0)'}');
    } catch (e) {
      print('❌ Error sending MAP toggle: $e');
    }
  }

  String _getMapToggleCode(String triggerLabel) {
    switch (triggerLabel) {
      case 'LOW BEAM':
        return 'SL'; // Map Low Beam
      case 'HIGH BEAM':
        return 'SH'; // Map High Beam
      case 'FOG LAMP':
        return 'SF'; // Map Fog Lamp
      default:
        return 'SQ'; // Default Map
    }
  }
Widget _buildQuickItem({
  required String label,
  required String? selectedValue,
  required Function(String?) onChanged,
}) {
  final isConnected = widget.socketService.isConnected;
  
  // Opsi untuk dropdown CALL
  final List<String> quickOptions = [
    "MATI",
    "REMOTE A",
    "REMOTE B", 
    "REMOTE C",
    "REMOTE D",
  ];

  // Pastikan selectedValue valid, jika tidak gunakan default
  final safeSelectedValue = selectedValue ?? 'MATI';

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.primaryBlack,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isConnected
            ? AppColors.neonGreen.withOpacity(0.5)
            : AppColors.neonGreen.withOpacity(0.2),
      ),
    ),
    child: Row(
      children: [
        // Label trigger
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: isConnected
                  ? AppColors.pureWhite
                  : AppColors.pureWhite.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Dropdown opsi trigger
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isConnected
                    ? AppColors.neonGreen
                    : AppColors.neonGreen.withOpacity(0.3),
              ),
            ),
            child: DropdownButton<String>(
              value: safeSelectedValue, // Gunakan safe value
              isExpanded: true,
              dropdownColor: AppColors.darkGrey,
              style: TextStyle(
                color: isConnected
                    ? AppColors.pureWhite
                    : AppColors.pureWhite.withOpacity(0.5),
                fontSize: 14,
              ),
              underline: const SizedBox(),
              icon: Icon(
                Icons.arrow_drop_down,
                color: isConnected
                    ? AppColors.neonGreen
                    : AppColors.neonGreen.withOpacity(0.3),
              ),
              items: quickOptions.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isConnected
                          ? AppColors.pureWhite
                          : AppColors.pureWhite.withOpacity(0.5),
                    ),
                  ),
                );
              }).toList(),
              onChanged: isConnected
                  ? (String? newValue) {
                      print('🎯 CALL dropdown selected: $newValue');
                      
                      // Pastikan newValue tidak null
                      if (newValue == null) return;
                      
                      // Update UI
                      setState(() {
                        _selectedQuick = newValue;
                      });
                      
                      // Simpan ke preferences
                      _saveTriggerSettings();
                      
                      // Kirim ke device
                      _sendQuickSetting(label, newValue);
                    }
                  : null,
            ),
          ),
        ),
      ],
    ),
  );
}

  // Method untuk mengirim setting QUICK saat onChanged
  void _sendQuickSetting(String triggerLabel, String? value) {
    // if (value == null || value == 'MATI' || !widget.socketService.isConnected) {
    //   return;
    // }

    try {
      final triggerIndex = _getTriggerIndex(value!);
      final modeCode = _getModeCode(value);

      widget.socketService.send('SQ$triggerIndex');
      print('✅ Sent $triggerLabel trigger: $value');

      _showSnackbar('$triggerLabel diatur ke: $value');
    } catch (e) {
      print('❌ Error sending $triggerLabel setting: $e');
    }
  }

  // Helper method untuk mode code
  String _getModeCode(String mode) {
    switch (mode) {
      case 'REMOTE A':
        return 'RA';
      case 'REMOTE B':
        return 'RB';
      case 'REMOTE C':
        return 'RC';
      case 'REMOTE D':
        return 'RD';
      default:
        return 'OFF';
    }
  }

  void _resetTriggerSettings() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    setState(() {
      _selectedQuick = null;
      _selectedLowBeam = null;
      _selectedHighBeam = null;
      _selectedFogLamp = null;
    });

    _saveTriggerSettings();

    _showSnackbar('Trigger settings telah direset!');
  }
}
