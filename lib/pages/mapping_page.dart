import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/default_animations_service.dart'; // Tambahkan ini
import 'package:ninexmano_matrix/services/firebase_data_service.dart';
import 'package:ninexmano_matrix/services/preferences_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class MappingPage extends StatefulWidget {
  final SocketService socketService;

  const MappingPage({super.key, required this.socketService});

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final PreferencesService _preferencesService = PreferencesService();
  final DefaultAnimationsService _defaultAnimationsService =
      DefaultAnimationsService(); // Tambahkan ini
  late ConfigModel? config;

  // Dropdown values untuk setiap tombol
  String? _selectedAnimationA;
  String? _selectedAnimationB;
  String? _selectedAnimationC;
  String? _selectedAnimationD;

  // Data dari preferences
  List<AnimationModel> _userAnimations = [];
  List<AnimationModel> _defaultAnimations = []; // Tambahkan ini
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSending = false;

  @override
  @override
  void initState() {
    super.initState();

    _preferencesService.getDeviceConfig().then((configValue) {
      setState(() {
        config = configValue;
      });
      _initializeData();
      _loadSavedMappings();
    });
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Starting initialization...');

      // 1. Load device config DULU (tapi jangan proses mappings yet)
      await _loadDeviceConfig();
      print('✅ Device config loaded');

      // 2. Load animations DULU
      await _loadAllAnimations();
      print('✅ Animations loaded, total: ${_allAnimations.length}');

      // 3. Baru load mappings (setelah animations ready)
      await _loadSavedMappings();
      print('✅ Mappings loaded');
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing data: $e';
      });
      print('❌ Error in _initializeData: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDeviceConfig() async {
    config = await _preferencesService.getDeviceConfig();
    print('📊 Device config loaded: ${config?.jumlahChannel} channels');
    // JANGAN panggil _loadSavedMappings() di sini!
  }

  // Load animasi dari semua sumber (default + user)
  Future<void> _loadAllAnimations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      print('🔄 Starting _loadAllAnimations...');

      // Load default animations
      await _defaultAnimationsService.initializeDefaultAnimations();
      final defaultAnimations = await _defaultAnimationsService
          .getDefaultAnimations();

      print('✅ Default animations loaded: ${defaultAnimations.length}');
      for (int i = 0; i < defaultAnimations.length; i++) {
        print('   ${i + 1}. ${defaultAnimations[i].name}');
      }

      // Load user animations
      print('🔄 Loading user animations...');
      final userAnimations = await _firebaseService.getUserSelectedAnimations();

      print('✅ User animations loaded: ${userAnimations.length}');
      for (int i = 0; i < userAnimations.length; i++) {
        print('   ${i + 1}. ${userAnimations[i].name}');
      }

      setState(() {
        _defaultAnimations = defaultAnimations;
        _userAnimations = userAnimations;
      });

      print('🎯 Final counts:');
      print('   Default: ${_defaultAnimations.length}');
      print('   User: ${_userAnimations.length}');
      print('   Total: ${_allAnimations.length}');
    } catch (e) {
      print('❌ Error loading animations: $e');
      setState(() {
        _errorMessage = 'Error loading animations: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get all animations (default + user) untuk dropdown
  List<AnimationModel> get _allAnimations {
    return [..._defaultAnimations, ..._userAnimations];
  }

  Future<void> _loadSavedMappings() async {
    try {
      if (config != null) {
        print(
          '📊 Config selections: ${config?.selection1}, ${config?.selection2}, ${config?.selection3}, ${config?.selection4}',
        );

        // Convert index dari config ke nama animasi
        setState(() {
          _selectedAnimationA = _getAnimationNameByIndex(
            config?.selection1 ?? 1,
          );
          _selectedAnimationB = _getAnimationNameByIndex(
            config?.selection2 ?? 1,
          );
          _selectedAnimationC = _getAnimationNameByIndex(
            config?.selection3 ?? 1,
          );
          _selectedAnimationD = _getAnimationNameByIndex(
            config?.selection4 ?? 2,
          );
        });

        print('🎯 Loaded mappings:');
        print('  A: ${config?.selection1}');
        print('  B: ${config?.selection2}');
        print('  C: ${config?.selection3}');
        print('  D: ${config?.selection4}');
      } else {
        print('⚠️ No config found, using default');
        _setDefaultFromIndex1();
      }

      print('✅ Loaded saved mappings from config');
    } catch (e) {
      print('❌ Error loading saved mappings: $e');
      _setDefaultFromIndex1();
    }
  }

  String? _getAnimationNameByIndex(int index) {
    // Index dari config biasanya 1-based, convert ke 0-based
    final zeroBasedIndex = index - 1;

    print(
      '🔍 Looking for animation index: $index (zero-based: $zeroBasedIndex)',
    );
    print('📁 Available animations: ${_allAnimations.length}');

    if (zeroBasedIndex >= 0 && zeroBasedIndex < _allAnimations.length) {
      final animationName = _allAnimations[zeroBasedIndex].name;
      print('✅ Found animation: $animationName for index $index');
      return animationName;
    } else {
      // Fallback ke index 0 jika index tidak valid
      print('⚠️ Invalid animation index: $index, using default');
      return _allAnimations.isNotEmpty ? _allAnimations[0].name : null;
    }
  }

  void _setDefaultFromIndex1() {
    if (_defaultAnimations.length > 1) {
      final defaultAnimation = _defaultAnimations[1]; // Index 1 = animasi kedua

      setState(() {
        _selectedAnimationA = defaultAnimation.name;
        _selectedAnimationB = null;
        _selectedAnimationC = null;
        _selectedAnimationD = null;
      });

      print('🎯 Set default mapping from index 1: ${defaultAnimation.name}');

      _saveMappings();
    }
  }

  // Validasi mapping
  String? _validateMapping(String? mappingValue) {
    if (mappingValue == null) return null;

    final exists = _allAnimations.any((anim) => anim.name == mappingValue);
    if (!exists) {
      print('⚠️ Removing invalid mapping: $mappingValue');
      return null;
    }

    return mappingValue;
  }

  Future<void> _saveMappings() async {
    try {
      // Convert nama animasi ke index (1-based)
      final indexA = _getIndexByAnimationName(_selectedAnimationA) ?? 1;
      final indexB = _getIndexByAnimationName(_selectedAnimationB) ?? 1;
      final indexC = _getIndexByAnimationName(_selectedAnimationC) ?? 1;
      final indexD = _getIndexByAnimationName(_selectedAnimationD) ?? 1;

      print('💾 Saving mappings as indexes:');
      print('   A: $_selectedAnimationA -> $indexA');
      print('   B: $_selectedAnimationB -> $indexB');
      print('   C: $_selectedAnimationC -> $indexC');
      print('   D: $_selectedAnimationD -> $indexD');

      // Simpan ke PreferencesService sebagai index
      if (config != null) {
        final updatedConfig = ConfigModel(
          // Copy semua property dari config existing
          firmware: config!.firmware,
          mac: config!.mac,
          typeLicense: config!.typeLicense,
          jumlahChannel: config!.jumlahChannel,
          email: config!.email,
          ssid: config!.ssid,
          password: config!.password,
          delay1: config!.delay1,
          delay2: config!.delay2,
          delay3: config!.delay3,
          delay4: config!.delay4,
          // Update selection indexes
          selection1: indexA,
          selection2: indexB,
          selection3: indexC,
          selection4: indexD,
          devID: config!.devID,
          mitraID: config!.mitraID,
          animWelcome: config!.animWelcome,
          durasiWelcome: config!.durasiWelcome,
          trigger1Data: config!.trigger1Data,
          trigger2Data: config!.trigger2Data,
          trigger3Data: config!.trigger3Data,
          trigger1Mode: config!.trigger1Mode,
          trigger2Mode: config!.trigger2Mode,
          trigger3Mode: config!.trigger3Mode,
          quickTrigger: config!.quickTrigger,
        );

        await _preferencesService.saveDeviceConfig(updatedConfig);

        // Update config state
        setState(() {
          config = updatedConfig;
        });

        print('✅ Config saved with index mappings');
      } else {
        _showSnackbar("error coba hubungkan keperangkat");
        print('✅ New config created with index mappings');
      }

      // Juga simpan nama ke preferences untuk UI (optional)
      final nameMappings = {
        'button_a': _selectedAnimationA,
        'button_b': _selectedAnimationB,
        'button_c': _selectedAnimationC,
        'button_d': _selectedAnimationD,
        'last_updated': DateTime.now().toIso8601String(),
      };

      await _preferencesService.saveUserSetting(
        'button_mappings',
        nameMappings,
      );
      print('✅ Name mappings saved to preferences');
    } catch (e) {
      print('❌ Error saving mappings: $e');
    }
  }

  // Helper method untuk mendapatkan index berdasarkan nama animasi (1-based)
  int _getIndexByAnimationName(String? animationName) {
    if (animationName == null) return 1; // Default ke index 1

    final index = _allAnimations.indexWhere(
      (anim) => anim.name == animationName,
    );
    if (index != -1) {
      return index + 1; // Convert ke 1-based index
    }

    print('⚠️ Animation not found: $animationName, using default index 1');
    return 1; // Fallback ke index 1
  }

  // ========== SOCKET ACTIONS ==========

  // Kirim animasi ke device berdasarkan mapping
  Future<void> _sendAllAnimations() async {
    if (_allAnimations.isEmpty || !widget.socketService.isConnected) return;

    // Validasi minimal satu animasi dipilih
    final selectedAnimations = [
      _selectedAnimationA,
      _selectedAnimationB,
      _selectedAnimationC,
      _selectedAnimationD,
    ].where((anim) => anim != null).toList();

    if (selectedAnimations.isEmpty) {
      _showSnackbar(
        'Pilih minimal satu animasi terlebih dahulu!',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      print('🔄 Mengirim animasi mapping ke device...');

      // Group by type untuk optimasi pengiriman
      final defaultAnimations = <Map<String, dynamic>>[];
      final customAnimations = <Map<String, dynamic>>[];

      // Kategorikan animasi berdasarkan type
      if (_selectedAnimationA != null) {
        final isDefault = _defaultAnimations.any(
          (anim) => anim.name == _selectedAnimationA,
        );
        if (isDefault) {
          defaultAnimations.add({'button': 1, 'name': _selectedAnimationA!});
        } else {
          customAnimations.add({'button': 1, 'name': _selectedAnimationA!});
        }
      }

      if (_selectedAnimationB != null) {
        final isDefault = _defaultAnimations.any(
          (anim) => anim.name == _selectedAnimationB,
        );
        if (isDefault) {
          defaultAnimations.add({'button': 2, 'name': _selectedAnimationB!});
        } else {
          customAnimations.add({'button': 2, 'name': _selectedAnimationB!});
        }
      }

      if (_selectedAnimationC != null) {
        final isDefault = _defaultAnimations.any(
          (anim) => anim.name == _selectedAnimationC,
        );
        if (isDefault) {
          defaultAnimations.add({'button': 3, 'name': _selectedAnimationC!});
        } else {
          customAnimations.add({'button': 3, 'name': _selectedAnimationC!});
        }
      }

      if (_selectedAnimationD != null) {
        final isDefault = _defaultAnimations.any(
          (anim) => anim.name == _selectedAnimationD,
        );
        if (isDefault) {
          defaultAnimations.add({'button': 4, 'name': _selectedAnimationD!});
        } else {
          customAnimations.add({'button': 4, 'name': _selectedAnimationD!});
        }
      }

      print(
        '📊 Sending ${defaultAnimations.length} default + ${customAnimations.length} custom animations',
      );

      // Kirim default animations dulu (lebih cepat)
      for (final item in defaultAnimations) {
        await _sendAnimationForButton(
          item['button'] as int,
          item['name'] as String,
        );
      }

      // Kirim custom animations
      for (final item in customAnimations) {
        await _sendAnimationForButton(
          item['button'] as int,
          item['name'] as String,
        );
      }

      // Simpan mapping terakhir yang dikirim
      await _firebaseService.saveUserSetting('last_sent_mappings', {
        'button_a': _selectedAnimationA,
        'button_b': _selectedAnimationB,
        'button_c': _selectedAnimationC,
        'button_d': _selectedAnimationD,
        'sent_at': DateTime.now().toIso8601String(),
      });

      _showSnackbar(
        '${selectedAnimations.length} animasi berhasil dikirim ke device!',
      );
    } catch (e) {
      _showSnackbar('Error mengirim animasi: $e', isError: true);
      print('❌ Error sending animations: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Kirim animasi untuk tombol tertentu
  Future<void> _sendAnimationForButton(
    int buttonIndex,
    String? animationName,
  ) async {
    if (animationName == null) return;

    // Cari animasi di semua sumber (default + user)
    final animation = _allAnimations.firstWhere(
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

    if (animation.name.isEmpty) {
      print('❌ Animation not found: $animationName');
      return;
    }

    // Cek apakah ini animasi default
    final isDefault = _defaultAnimations.any(
      (anim) => anim.name == animationName,
    );

    if (isDefault) {
      // Kirim menggunakan format B[kode remot][index animasi 2 digit]
      await _sendDefaultAnimation(buttonIndex, animation);
    } else {
      // Kirim menggunakan format biasa (frame data)
      await _sendCustomAnimation(buttonIndex, animation);
    }
  }

  // Kirim animasi default dengan format B[kode remot][index animasi]
  // Kirim animasi default dengan format B[kode remot][index animasi]
  Future<void> _sendDefaultAnimation(
    int buttonIndex,
    AnimationModel animation,
  ) async {
    try {
      // Cari index animasi default (1-31)
      final defaultIndex = _defaultAnimations.indexWhere(
        (anim) => anim.name == animation.name,
      );

      if (defaultIndex == -1) {
        print('❌ Default animation index not found: ${animation.name}');
        return;
      }

      final animationIndex = defaultIndex + 1; // Convert to 1-based index

      print(
        '🎯 Sending default animation: B$buttonIndex${animationIndex.toString().padLeft(2, '0')} - ${animation.name}',
      );

      widget.socketService.setBuiltinAnimation(buttonIndex, animationIndex);

      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      print('❌ Error sending default animation: $e');
      throw e;
    }
  }

  // Kirim animasi custom (user animations) dengan frame data
  Future<void> _sendCustomAnimation(
    int buttonIndex,
    AnimationModel animation,
  ) async {
    print(
      '📤 Sending custom animation for Button ${_getButtonLabel(buttonIndex)}: ${animation.name}',
    );

    // Kirim frame data untuk setiap channel (A-J)
    await _sendAnimationFrames(buttonIndex, animation);

    // Kirim delay data
    await _sendAnimationDelay(buttonIndex, animation);

    print(
      '✅ Successfully sent custom animation for Button ${_getButtonLabel(buttonIndex)}',
    );
  }

  // Method _sendAnimationFrames, _getDeviceChannelCount, _calculateFramesPerChannel,
  // _extractChannelDataForDevice, _getFrameDataForChannelFrame, _extractChannelData
  // tetap sama seperti sebelumnya...

  Future<void> _sendAnimationFrames(
    int buttonIndex,
    AnimationModel animation,
  ) async {
    final deviceChannelCount = config?.jumlahChannel ?? 8;
    // final framesPerChannel = _calculateFramesPerChannel(deviceChannelCount);

    // print(
    //   '📊 Device Channels: $deviceChannelCount, Frames per Channel: $framesPerChannel',
    // );

    widget.socketService.uploadAnimation(
      remoteIndex: buttonIndex,
      channel: "A",
      frameIndex: animation.animationLength,
      hexData: animation.frameData[0],
    );
    if (deviceChannelCount > 8) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "B",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[1],
      );
    }
    if (deviceChannelCount > 16) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "C",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[2],
      );
    }
    if (deviceChannelCount > 24) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "D",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[3],
      );
    }
    if (deviceChannelCount > 32) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "E",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[4],
      );
    }
    if (deviceChannelCount > 40) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "F",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[5],
      );
    }
    if (deviceChannelCount > 48) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "G",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[6],
      );
    }
    if (deviceChannelCount > 56) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "H",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[7],
      );
    }
    if (deviceChannelCount > 64) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "I",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[8],
      );
    }
    if (deviceChannelCount > 72) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "J",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[9],
      );
    }
    if (deviceChannelCount > 80) {
      widget.socketService.uploadAnimation(
        remoteIndex: buttonIndex,
        channel: "K",
        frameIndex: animation.animationLength,
        hexData: animation.frameData[10],
      );
    }

    // }
  }

  int _calculateFramesPerChannel(int deviceChannelCount) {
    if (deviceChannelCount <= 8) return 1;
    if (deviceChannelCount <= 16) return 2;
    if (deviceChannelCount <= 24) return 3;
    return 4; // Untuk 32 channels
  }

  String _extractChannelDataForDevice(
    AnimationModel animation,
    int channelIndex,
    int deviceChannelCount,
  ) {
    final buffer = StringBuffer();
    final framesPerChannel = _calculateFramesPerChannel(deviceChannelCount);

    for (final frame in animation.frameData) {
      print("frame>> ${frame}");
      //   for (int frameOffset = 0; frameOffset < framesPerChannel; frameOffset++) {
      //     final actualChannelIndex = channelIndex + (frameOffset * 8);
      //     if (actualChannelIndex < deviceChannelCount) {
      //       final hexPosition = actualChannelIndex * 2;
      //       if (hexPosition + 2 <= frame.length) {
      //         buffer.write(frame.substring(hexPosition, hexPosition + 2));
      //       } else {
      //         buffer.write('00'); // Padding jika data tidak cukup
      //       }
      //     }
      //   }
    }

    return buffer.toString();
  }

  String _getFrameDataForChannelFrame(
    String channelData,
    int frameIndex,
    int framesPerChannel,
  ) {
    final totalFrames = channelData.length ~/ (framesPerChannel * 2);
    final frameLength = totalFrames * 2;

    final start = frameIndex * frameLength;
    final end = start + frameLength;

    if (end <= channelData.length) {
      return channelData.substring(start, end);
    }

    return '';
  }

  String _extractChannelData(AnimationModel animation, int channelIndex) {
    final buffer = StringBuffer();

    for (final frame in animation.frameData) {
      if (frame.length > channelIndex * 2) {
        final start = channelIndex * 2;
        final end = start + 2;
        if (end <= frame.length) {
          buffer.write(frame.substring(start, end));
        } else {
          buffer.write('00'); // Padding
        }
      } else {
        buffer.write('00'); // Padding
      }
    }

    return buffer.toString();
  }

  // Kirim delay data animasi
  Future<void> _sendAnimationDelay(
    int buttonIndex,
    AnimationModel animation,
  ) async {
    if (animation.delayData.isNotEmpty) {
      final delayType = _getDelayType(buttonIndex); // K, L, M, N

      widget.socketService.uploadDelay(
        remoteIndex: buttonIndex,
        delayType: delayType,
        frameIndex: 1,
        delayData: animation.delayData,
      );
    }
  }

  // Method untuk mengirim animasi individual
  Future<void> _sendSingleAnimation(
    int buttonIndex,
    String? animationName,
  ) async {
    if (animationName == null || animationName.isEmpty) {
      _showSnackbar(
        'Pilih animasi terlebih dahulu untuk Tombol ${_getButtonLabel(buttonIndex)}',
        isError: true,
      );
      return;
    }

    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device', isError: true);
      return;
    }

    try {
      print(
        '🔄 Mengirim animasi individual untuk Tombol ${_getButtonLabel(buttonIndex)}: $animationName',
      );

      // Cari animasi di semua sumber (default + user)
      final animation = _allAnimations.firstWhere(
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

      if (animation.name.isEmpty) {
        _showSnackbar('Animasi tidak ditemukan: $animationName', isError: true);
        return;
      }

      // Cek apakah ini animasi default
      final isDefault = _defaultAnimations.any(
        (anim) => anim.name == animationName,
      );

      if (isDefault) {
        // Kirim animasi default
        await _sendDefaultAnimation(buttonIndex, animation);
      } else {
        // Kirim animasi custom
        await _sendCustomAnimation(buttonIndex, animation);
      }

      _showSnackbar(
        'Animasi berhasil dikirim ke Tombol ${_getButtonLabel(buttonIndex)}: $animationName',
      );
    } catch (e) {
      _showSnackbar('Error mengirim animasi: $e', isError: true);
      print('❌ Error sending single animation: $e');
    }
  }

  // Helper method untuk mendapatkan label tombol
  String _getButtonLabel(int buttonIndex) {
    switch (buttonIndex) {
      case 1:
        return 'A';
      case 2:
        return 'B';
      case 3:
        return 'C';
      case 4:
        return 'D';
      default:
        return '?';
    }
  }

  String _getDelayType(int buttonIndex) {
    switch (buttonIndex) {
      case 1:
        return 'K';
      case 2:
        return 'L';
      case 3:
        return 'M';
      case 4:
        return 'N';
      default:
        return 'K';
    }
  }

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
              // Container untuk 4 settingan
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
                      'Animation Mapping',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Statistics
                    Text(
                      '${_defaultAnimations.length} default + ${_userAnimations.length} user animations',
                      style: TextStyle(
                        color: AppColors.pureWhite.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                              onPressed: _loadAllAnimations,
                              icon: Icon(Icons.refresh, color: Colors.red),
                              iconSize: 20,
                            ),
                          ],
                        ),
                      )
                    // Empty State
                    else if (_allAnimations.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neonGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.animation_outlined,
                              color: AppColors.pureWhite.withOpacity(0.5),
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No animations found',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Download animations from Cloud Files first',
                              style: TextStyle(
                                color: AppColors.pureWhite.withOpacity(0.5),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    // Mapping Items
                    else ...[
                      // Setting Tombol A
                      // Di dalam build method, ganti pemanggilan _buildMappingItem:

                      // Setting Tombol A
                      _buildMappingItem(
                        label: 'TOMBOL A :',
                        selectedValue: _selectedAnimationA,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationA = value;
                          });
                          _saveMappings();
                        },
                        sendPerAnim: () => _sendSingleAnimation(
                          1,
                          _selectedAnimationA,
                        ), // Button A = index 1
                      ),

                      // Setting Tombol B
                      _buildMappingItem(
                        label: 'TOMBOL B :',
                        selectedValue: _selectedAnimationB,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationB = value;
                          });
                          _saveMappings();
                        },
                        sendPerAnim: () => _sendSingleAnimation(
                          2,
                          _selectedAnimationB,
                        ), // Button B = index 2
                      ),

                      // Setting Tombol C
                      _buildMappingItem(
                        label: 'TOMBOL C :',
                        selectedValue: _selectedAnimationC,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationC = value;
                          });
                          _saveMappings();
                        },
                        sendPerAnim: () => _sendSingleAnimation(
                          3,
                          _selectedAnimationC,
                        ), // Button C = index 3
                      ),

                      // Setting Tombol D
                      _buildMappingItem(
                        label: 'TOMBOL D :',
                        selectedValue: _selectedAnimationD,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationD = value;
                          });
                          _saveMappings();
                        },
                        sendPerAnim: () => _sendSingleAnimation(
                          4,
                          _selectedAnimationD,
                        ), // Button D = index 4
                      ),
                    ],
                  ],
                ),
              ),

              // const SizedBox(height: 20),

              // // Tombol KIRIM SEMUA
              // SizedBox(
              //   width: double.infinity,
              //   height: 50,
              //   child: ElevatedButton(
              //     onPressed:
              //         (_allAnimations.isEmpty ||
              //             !widget.socketService.isConnected ||
              //             _isSending)
              //         ? null
              //         : _sendAllAnimations,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor:
              //           (_allAnimations.isEmpty ||
              //               !widget.socketService.isConnected)
              //           ? AppColors.neonGreen.withOpacity(0.3)
              //           : AppColors.neonGreen,
              //       foregroundColor: AppColors.primaryBlack,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12),
              //       ),
              //     ),
              //     child: _isSending
              //         ? const Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               SizedBox(
              //                 width: 20,
              //                 height: 20,
              //                 child: CircularProgressIndicator(
              //                   strokeWidth: 2,
              //                   color: AppColors.primaryBlack,
              //                 ),
              //               ),
              //               SizedBox(width: 8),
              //               Text('MENGIRIM...'),
              //             ],
              //           )
              //         : const Text(
              //             'KIRIM SEMUA KE DEVICE',
              //             style: TextStyle(
              //               fontSize: 16,
              //               fontWeight: FontWeight.bold,
              //             ),
              //           ),
              //   ),
              // ),

              // Info Panel
              if (_allAnimations.isNotEmpty) ...[
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
                        'Mapping Summary',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMappingInfo('Button A', _selectedAnimationA),
                      _buildMappingInfo('Button B', _selectedAnimationB),
                      _buildMappingInfo('Button C', _selectedAnimationC),
                      _buildMappingInfo('Button D', _selectedAnimationD),
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

  Widget _buildConnectionInfo() {
    return Row(
      children: [
        Icon(Icons.info, color: AppColors.neonGreen, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.socketService.isConnected
                ? 'Animasi akan dikirim ke device'
                : 'Connect ke device terlebih dahulu untuk mengirim animasi',
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

  Widget _buildMappingItem({
  required String label,
  required String? selectedValue,
  required Function(String?) onChanged,
  required Function() sendPerAnim,
}) {
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
        // Baris pertama: Label dan Tombol Kirim
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Tombol Kirim - lebih kecil
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: selectedValue != null && selectedValue!.isNotEmpty
                    ? sendPerAnim
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neonGreen,
                  foregroundColor: AppColors.primaryBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  disabledBackgroundColor: AppColors.darkGrey,
                  disabledForegroundColor: AppColors.pureWhite.withOpacity(0.5),
                ),
                child: const Text(
                  'KIRIM',
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Baris kedua: Dropdown animasi
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.neonGreen),
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            isExpanded: true,
            dropdownColor: AppColors.darkGrey,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 13,
            ),
            underline: const SizedBox(),
            icon: Icon(
              Icons.arrow_drop_down, 
              color: AppColors.neonGreen,
              size: 20,
            ),
            hint: Text(
              'Pilih animation...',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
            items: _buildDropdownItems(),
            onChanged: onChanged,
          ),
        ),
      ],
    ),
  );
}
  List<DropdownMenuItem<String>> _buildDropdownItems() {
  final items = <DropdownMenuItem<String>>[
    // Item untuk clear selection
    DropdownMenuItem<String>(
      value: null,
      child: Text(
        'Tidak ada animasi',
        style: TextStyle(
          color: AppColors.pureWhite.withOpacity(0.5),
          fontStyle: FontStyle.italic,
        ),
        overflow: TextOverflow.ellipsis, // Tambahkan ini
      ),
    ),
  ];

  // Add default animations FIRST dengan label khusus
  items.addAll(
    _defaultAnimations.map((animation) {
      return DropdownMenuItem<String>(
        value: animation.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded( // Tambahkan Expanded di sini
                  child: Text(
                    animation.name,
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Tambahkan ini
                    maxLines: 1, // Tambahkan ini
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    'DEFAULT',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${animation.channelCount}C • ${animation.animationLength}L • ${animation.totalFrames}F',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis, // Tambahkan ini
              maxLines: 1, // Tambahkan ini
            ),
          ],
        ),
      );
    }).toList(),
  );

  // Add separator antara default dan user animations
  if (_defaultAnimations.isNotEmpty && _userAnimations.isNotEmpty) {
    items.add(
      DropdownMenuItem<String>(
        enabled: false,
        value: '__separator__',
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: AppColors.neonGreen.withOpacity(0.3),
        ),
      ),
    );
  }

  // Add user animations
  items.addAll(
    _userAnimations.map((animation) {
      return DropdownMenuItem<String>(
        value: animation.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              animation.name,
              style: TextStyle(
                color: AppColors.pureWhite,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis, // Tambahkan ini
              maxLines: 1, // Tambahkan ini
            ),
            Text(
              '${animation.channelCount}C • ${animation.animationLength}L • ${animation.totalFrames}F',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis, // Tambahkan ini
              maxLines: 1, // Tambahkan ini
            ),
          ],
        ),
      );
    }).toList(),
  );

  return items;
}

 Widget _buildMappingInfo(String buttonName, String? animationName) {
  // Cari animasi di semua sumber
  final animation = _allAnimations.firstWhere(
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

  final isDefault = _defaultAnimations.any(
    (anim) => anim.name == animationName,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2.0),
    child: Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$buttonName:',
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.7),
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis, // Tambahkan ini
            maxLines: 1, // Tambahkan ini
          ),
        ),
        if (animationName != null && animation.name.isNotEmpty)
          Expanded(
            child: Row(
              children: [
                Expanded( // Tambahkan Expanded di sini
                  child: Text(
                    animationName,
                    style: TextStyle(
                      color: isDefault ? Colors.blue : AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Tambahkan ini
                    maxLines: 1, // Tambahkan ini
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDefault
                        ? Colors.blue.withOpacity(0.2)
                        : AppColors.neonGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDefault ? Colors.blue : AppColors.neonGreen,
                    ),
                  ),
                  child: Text(
                    isDefault ? 'DEFAULT' : 'CUSTOM',
                    style: TextStyle(
                      color: isDefault ? Colors.blue : AppColors.neonGreen,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!isDefault) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neonGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.channelCount}C',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.animationLength}L',
                      style: TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.totalFrames}F',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ] else ...[
                  // Tampilkan index untuk default animations
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ID: ${_getDefaultAnimationIndex(animationName).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Expanded( // Tambahkan Expanded di sini juga
            child: Text(
              'Not assigned',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis, // Tambahkan ini
              maxLines: 1, // Tambahkan ini
            ),
          ),
      ],
    ),
  );
}

  // Helper method untuk mendapatkan index animasi default
  int _getDefaultAnimationIndex(String animationName) {
    final index = _defaultAnimations.indexWhere(
      (anim) => anim.name == animationName,
    );
    return index + 1; // Convert to 1-based index
  }
}
