import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/pages/map_editor_modal.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class TriggerPage extends StatefulWidget {
  final SocketService socketService;

  const TriggerPage({super.key, required this.socketService});

  @override
  State<TriggerPage> createState() => _TriggerPageState();
}

class _TriggerPageState extends State<TriggerPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();

  // Dropdown values untuk setiap trigger
  String? _selectedQuick;
  String? _selectedLowBeam;
  String? _selectedHighBeam;
  String? _selectedFogLamp;

  // Data dari My File
  List<AnimationModel> _userAnimations = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserAnimations();
    _loadSavedTriggerSettings();
  }

  // Handler untuk fallback ke index 1 jika selection tidak ada
  String _getSafeSelection(
    String? selectedValue,
    List<String> availableOptions,
  ) {
    if (selectedValue == null || selectedValue.isEmpty) {
      return availableOptions.isNotEmpty ? availableOptions[0] : 'MATI';
    }

    // Cek jika selectedValue ada di availableOptions
    if (availableOptions.contains(selectedValue)) {
      return selectedValue;
    }

    // Fallback ke index 1 (atau index 0 jika hanya ada 1 option)
    return availableOptions.length > 1
        ? availableOptions[1]
        : availableOptions[0];
  }

  // Handler khusus untuk trigger settings dengan fallback
  void _handleTriggerSelection(String? newValue, Function(String?) onChanged) {
    if (newValue == null) return;

    // Default fallback options berdasarkan trigger type
    final List<String> fallbackOptions = [
      'MATI',
      'REMOTE A',
      'REMOTE B',
      'REMOTE C',
      'REMOTE D',
      'MAP STATIS',
      'MAP DINAMIS',
    ];

    // Jika value tidak valid, fallback ke index 1
    final safeValue = fallbackOptions.contains(newValue)
        ? newValue
        : (fallbackOptions.length > 1
              ? fallbackOptions[1]
              : fallbackOptions[0]);

    onChanged(safeValue);
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
        'REMOTE A',
        'REMOTE B',
        'REMOTE C',
        'REMOTE D',
        'MATI',
      ];
      final safeSetting = validSettings.contains(setting)
          ? setting
          : 'REMOTE A'; // Fallback ke REMOTE A

      final modeCode = _getModeCode(safeSetting);
      widget.socketService.send('S$safeTriggerIndex$modeCode');

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
    switch (triggerType) {
      case 'QUICK':
        return 1;
      case 'LOW':
        return 2;
      case 'HIGH':
        return 3;
      case 'FOG':
        return 4;
      default:
        return -1;
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

  // Method untuk membuka modal editor MAP
  void _openMapEditor(String triggerLabel) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    MapEditorModal.show(
      context: context,
      triggerLabel: triggerLabel,
      socketService: widget.socketService,
      onMapDataCreated: (mapData) {
        _sendMapDataToDevice(triggerLabel, mapData);
      },
    );
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
        return 1;
      case 'LOW BEAM':
        return 2;
      case 'HIGH BEAM':
        return 3;
      case 'FOG LAMP':
        return 4;
      default:
        return 1;
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
                        label: 'QUICK',
                        selectedValue: _selectedQuick,
                        onChanged: (value) {
                          if (!isConnected) return;

                          // List options untuk QUICK
                          final safeValue = _validateDropdownValue(value, [
                            "MATI",
                            "REMOTE A",
                            "REMOTE B",
                            "REMOTE C",
                            "REMOTE D",
                            "MAP STATIS",
                          ]);

                          setState(() {
                            _selectedQuick = safeValue;
                          });
                          _saveTriggerSettings();

                          // Kirim langsung ke device
                          _sendQuickSettingWithFallback('QUICK', safeValue);
                        },
                      ),

                      // Setting LOW BEAM
                      _buildTriggerItem(
                        label: 'LOW BEAM',
                        selectedValue: _selectedLowBeam,
                        onChanged: (value) {
                          if (!isConnected) return;

                          setState(() {
                            _selectedLowBeam = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),

                      // Setting HIGH BEAM
                      _buildTriggerItem(
                        label: 'HIGH BEAM',
                        selectedValue: _selectedHighBeam,
                        onChanged: (value) {
                          if (!isConnected) return;

                          setState(() {
                            _selectedHighBeam = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),

                      // Setting FOG LAMP
                      _buildTriggerItem(
                        label: 'FOG LAMP',
                        selectedValue: _selectedFogLamp,
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
              if (_userAnimations.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.neonGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trigger Summary',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildTriggerInfo('LOW BEAM', _selectedLowBeam),
                      _buildTriggerInfo('HIGH BEAM', _selectedHighBeam),
                      _buildTriggerInfo('FOG LAMP', _selectedFogLamp),
                      const SizedBox(height: 8),
                      Divider(color: AppColors.neonGreen.withOpacity(0.3)),
                      _buildConnectionInfo(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisconnectedWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.errorRed, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Tidak Terkoneksi',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Semua kontrol dinonaktifkan. Tap Connect di Dashboard untuk melanjutkan.',
                  style: TextStyle(
                    color: AppColors.errorRed.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = widget.socketService.isConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? AppColors.successGreen : AppColors.errorRed,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.successGreen : AppColors.errorRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isConnected
                  ? 'Terhubung - Siap mengirim trigger settings'
                  : 'DISCONNECTED - Tap Connect di Dashboard',
              style: TextStyle(
                color: isConnected
                    ? AppColors.successGreen
                    : AppColors.errorRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          if (!isConnected)
            Icon(Icons.warning_amber, color: AppColors.errorRed, size: 20),
        ],
      ),
    );
  }

  Widget _buildConnectionInfo() {
    final isConnected = widget.socketService.isConnected;

    return Row(
      children: [
        Icon(
          Icons.info,
          color: isConnected ? AppColors.neonGreen : AppColors.errorRed,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isConnected
                ? 'Trigger settings akan dikirim ke device via socket connection'
                : 'Connect ke device terlebih dahulu untuk mengirim trigger settings',
            style: TextStyle(
              color: isConnected ? AppColors.neonGreen : AppColors.errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // FIXED: Implementasi _buildTriggerItem yang benar
  Widget _buildTriggerItem({
    required String label,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    final isConnected = widget.socketService.isConnected;

    // HAPUS CUSTOM ANIMATION - hanya MAP modes saja
    // final List<String> triggerOptions = [
    //   "MATI",
    //   "MAP STATIS",
    //   "MAP DINAMIS",
    //   // HAPUS: ..._userAnimations.map((anim) => anim.name),
    // ];

    // Tentukan apakah mode MAP aktif dan jenisnya
    bool isMapStatic = selectedValue == 'MAP STATIS';
    bool isMapDynamic = selectedValue == 'MAP DINAMIS';

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
          // Baris pertama: Label dan Dropdown
          Row(
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
            ],
          ),

          // Baris kedua: Tombol MAP dan Toggle (hanya muncul jika MAP dipilih)
          // if (isMapStatic || isMapDynamic) ...[
          const SizedBox(height: 12),
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

                // Label KEDIP
                Text(
                  'KEDIP',
                  style: TextStyle(
                    color: isMapDynamic
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
                    value: isMapStatic,
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
                        ? (value) {
                            // Toggle antara MAP STATIS dan MAP DINAMIS
                            final newValue = value
                                ? 'MAP STATIS'
                                : 'MAP DINAMIS';
                            onChanged(newValue);
                          }
                        : null,
                  ),
                ),

                const SizedBox(width: 8),

                // Label STATIS
                Text(
                  'STATIS',
                  style: TextStyle(
                    color: isMapStatic
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

          // Info tambahan untuk mode MAP
          const SizedBox(height: 8),
          Text(
            isMapStatic
                ? 'Mode MAP STATIS: Gambar tetap menyala'
                : 'Mode MAP DINAMIS: Gambar berkedip',
            style: TextStyle(
              color: AppColors.neonGreen.withOpacity(isConnected ? 0.7 : 0.3),
              fontSize: 11,
            ),
          ),
          // ],
        ],
      ),
    );
  }

  // FIXED: Implementasi _buildQuickItem yang benar
  Widget _buildQuickItem({
    required String label,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    final isConnected = widget.socketService.isConnected;

    // Opsi untuk dropdown QUICK
    final List<String> quickOptions = [
      "MATI",
      "REMOTE A",
      "REMOTE B",
      "REMOTE C",
      "REMOTE D",
    ];

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
                value: selectedValue,
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
                hint: Text(
                  isConnected ? 'Pilih Mode' : 'DISCONNECTED',
                  style: TextStyle(
                    color: isConnected
                        ? AppColors.pureWhite.withOpacity(0.7)
                        : AppColors.pureWhite.withOpacity(0.3),
                    fontSize: 14,
                  ),
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
                    ? (value) {
                        // Kirim data langsung saat onChanged
                        onChanged(value);
                        _sendQuickSetting(label, value);
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
    if (value == null || value == 'MATI' || !widget.socketService.isConnected) {
      return;
    }

    try {
      final triggerIndex = _getTriggerIndex(triggerLabel);
      final modeCode = _getModeCode(value);

      widget.socketService.send('S$triggerIndex$modeCode');
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

  Widget _buildCustomAnimationItem(String animationName, bool isConnected) {
    final animation = _userAnimations.firstWhere(
      (anim) => anim.name == animationName,
      orElse: () => AnimationModel(
        name: '',
        channelCount: 0,
        animationLength: 0,
        description: '',
        delayData: '',
        frameData: [],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          animationName,
          style: TextStyle(
            color: isConnected
                ? AppColors.neonGreen
                : AppColors.neonGreen.withOpacity(0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${animation.channelCount}C • ${animation.totalFrames}F',
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(isConnected ? 0.7 : 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerInfo(String triggerName, String? setting) {
    final isConnected = widget.socketService.isConnected;
    final isCustomAnimation = _isCustomAnimation(setting);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$triggerName:',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(isConnected ? 0.7 : 0.3),
                fontSize: 12,
              ),
            ),
          ),
          if (setting != null)
            Expanded(
              child: Row(
                children: [
                  Text(
                    setting,
                    style: TextStyle(
                      color: isCustomAnimation
                          ? (isConnected
                                ? AppColors.neonGreen
                                : AppColors.neonGreen.withOpacity(0.3))
                          : AppColors.pureWhite.withOpacity(
                              isConnected ? 1.0 : 0.3,
                            ),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCustomAnimation) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(
                          isConnected ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CUSTOM',
                        style: TextStyle(
                          color: AppColors.neonGreen.withOpacity(
                            isConnected ? 1.0 : 0.3,
                          ),
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            Text(
              'Not set',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(isConnected ? 0.5 : 0.3),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
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
