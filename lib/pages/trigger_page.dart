import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class TriggerPage extends StatefulWidget {
  final SocketService socketService;
  
  const TriggerPage({
    super.key,
    required this.socketService,
  });

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

  // List opsi yang tersedia (termasuk animasi dari My File)
  final List<String> _triggerOptions = [
    'MATI',
    'MAP STATIS',
    'MAP DINAMIS',
    'ANIMASI WAVE',
    'ANIMASI SPIRAL',
    'ANIMASI TEXT',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAnimations();
    _loadSavedTriggerSettings();
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
      final settings = await _firebaseService.getUserSetting('trigger_settings') as Map<String, dynamic>?;
      
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

      _showSnackbar('${selectedTriggers.length} trigger settings berhasil dikirim ke device!');

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
    return {
      'type': setting,
      'trigger_index': triggerIndex,
    };
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
      _sendCustomAnimationTrigger(triggerIndex, animationName, channelCount, frameData, delayData);
    } else {
      // Kirim built-in mode
      _sendBuiltInTrigger(triggerIndex, type);
    }
  }

  // Kirim animasi custom untuk trigger
  void _sendCustomAnimationTrigger(int triggerIndex, String animationName, int channelCount, List<String> frameData, String delayData) {
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
      case 'QUICK': return 1;
      case 'LOW': return 2;
      case 'HIGH': return 3;
      case 'FOG': return 4;
      default: return -1;
    }
  }

  String _getModeCode(String mode) {
    switch (mode) {
      case 'MAP STATIS': return 'STATIC';
      case 'MAP DINAMIS': return 'DYNAMIC';
      case 'ANIMASI WAVE': return 'WAVE';
      case 'ANIMASI SPIRAL': return 'SPIRAL';
      case 'ANIMASI TEXT': return 'TEXT';
      default: return 'OFF';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Connection Status
              _buildConnectionStatus(),
              const SizedBox(height: 16),

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
                    if (_userAnimations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '${_userAnimations.length} custom animations available',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Loading Indicator
                    if (_isLoading)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppColors.neonGreen),
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
                      _buildTriggerItem(
                        label: 'QUICK',
                        selectedValue: _selectedQuick,
                        onChanged: (value) {
                          setState(() {
                            _selectedQuick = value;
                          });
                          _saveTriggerSettings();
                        },
                      ),
                      
                      // Setting LOW BEAM
                      _buildTriggerItem(
                        label: 'LOW BEAM',
                        selectedValue: _selectedLowBeam,
                        onChanged: (value) {
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
                  onPressed: (!widget.socketService.isConnected || _isLoading) 
                      ? null 
                      : _sendTriggerSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (!widget.socketService.isConnected || _isLoading)
                        ? AppColors.neonGreen.withOpacity(0.3)
                        : AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'KIRIM KE DEVICE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                  onPressed: _resetTriggerSettings,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.neonGreen,
                    side: BorderSide(color: AppColors.neonGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'RESET',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
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
                      _buildTriggerInfo('QUICK', _selectedQuick),
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
                  ? 'Terhubung - Siap mengirim trigger settings' 
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

  Widget _buildConnectionInfo() {
    return Row(
      children: [
        Icon(
          Icons.info,
          color: AppColors.neonGreen,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.socketService.isConnected
                ? 'Trigger settings akan dikirim ke device via socket connection'
                : 'Connect ke device terlebih dahulu untuk mengirim trigger settings',
            style: TextStyle(
              color: widget.socketService.isConnected
                  ? AppColors.neonGreen
                  : AppColors.errorRed,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerItem({
    required String label,
    required String? selectedValue,
    required Function(String?) onChanged,
  }) {
    // Gabungkan built-in options dengan custom animations
    final allOptions = [..._triggerOptions, ..._userAnimations.map((anim) => anim.name)];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          // Label trigger
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
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
                border: Border.all(color: AppColors.neonGreen),
              ),
              child: DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                dropdownColor: AppColors.darkGrey,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 14,
                ),
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen),
                hint: Text(
                  'Pilih Mode',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                items: allOptions.map((String option) {
                  final isCustomAnimation = _userAnimations.any((anim) => anim.name == option);
                  
                  return DropdownMenuItem<String>(
                    value: option,
                    child: isCustomAnimation
                        ? _buildCustomAnimationItem(option)
                        : Text(
                            option,
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                            ),
                          ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAnimationItem(String animationName) {
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
            color: AppColors.neonGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${animation.channelCount}C • ${animation.totalFrames}F',
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildTriggerInfo(String triggerName, String? setting) {
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
                color: AppColors.pureWhite.withOpacity(0.7),
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
                      color: isCustomAnimation ? AppColors.neonGreen : AppColors.pureWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isCustomAnimation) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CUSTOM',
                        style: TextStyle(
                          color: AppColors.neonGreen,
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
                color: AppColors.pureWhite.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  void _resetTriggerSettings() {
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