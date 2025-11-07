import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/default_animations_service.dart'; // Tambahkan ini
import 'package:ninexmano_matrix/services/firebase_data_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class MappingPage extends StatefulWidget {
  final SocketService socketService;
  
  const MappingPage({
    super.key,
    required this.socketService,
  });

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  final DefaultAnimationsService _defaultAnimationsService = DefaultAnimationsService(); // Tambahkan ini
  
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
  void initState() {
    super.initState();
    _loadAllAnimations(); // Ubah dari _loadUserAnimations
    _loadSavedMappings();
  }

  // Load animasi dari semua sumber (default + user)
  Future<void> _loadAllAnimations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load default animations
      await _defaultAnimationsService.initializeDefaultAnimations();
      final defaultAnimations = await _defaultAnimationsService.getDefaultAnimations();
      
      // Load user animations
      final userAnimations = await _firebaseService.getUserSelectedAnimations();
      
      setState(() {
        _defaultAnimations = defaultAnimations;
        _userAnimations = userAnimations;
        _isLoading = false;
      });

      print('✅ Loaded ${_defaultAnimations.length} default + ${_userAnimations.length} user animations for mapping');

    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading animations: $e';
        _isLoading = false;
      });
      print('❌ Error loading animations for mapping: $e');
    }
  }

  // Get all animations (default + user) untuk dropdown
  List<AnimationModel> get _allAnimations {
    return [..._defaultAnimations, ..._userAnimations];
  }

  // Load saved mappings dari preferences
  Future<void> _loadSavedMappings() async {
    try {
      final mappings = await _firebaseService.getUserSetting('button_mappings') as Map<String, dynamic>?;
      
      if (mappings != null) {
        setState(() {
          _selectedAnimationA = mappings['button_a'];
          _selectedAnimationB = mappings['button_b'];
          _selectedAnimationC = mappings['button_c'];
          _selectedAnimationD = mappings['button_d'];
        });
        
        print('✅ Loaded saved mappings from preferences');
      }
    } catch (e) {
      print('❌ Error loading saved mappings: $e');
    }
  }

  // Save mappings ke preferences
  Future<void> _saveMappings() async {
    try {
      final mappings = {
        'button_a': _selectedAnimationA,
        'button_b': _selectedAnimationB,
        'button_c': _selectedAnimationC,
        'button_d': _selectedAnimationD,
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _firebaseService.saveUserSetting('button_mappings', mappings);
      print('💾 Saved mappings to preferences');
    } catch (e) {
      print('❌ Error saving mappings: $e');
    }
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
      _showSnackbar('Pilih minimal satu animasi terlebih dahulu!', isError: true);
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      print('🔄 Mengirim animasi mapping ke device...');
      
      // Kirim animasi untuk setiap tombol yang dipilih
      await _sendAnimationForButton(1, _selectedAnimationA);
      await _sendAnimationForButton(2, _selectedAnimationB);
      await _sendAnimationForButton(3, _selectedAnimationC);
      await _sendAnimationForButton(4, _selectedAnimationD);

      // Simpan mapping terakhir yang dikirim
      await _firebaseService.saveUserSetting('last_sent_mappings', {
        'button_a': _selectedAnimationA,
        'button_b': _selectedAnimationB,
        'button_c': _selectedAnimationC,
        'button_d': _selectedAnimationD,
        'sent_at': DateTime.now().toIso8601String(),
      });

      _showSnackbar('${selectedAnimations.length} animasi berhasil dikirim ke device!');

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
  Future<void> _sendAnimationForButton(int buttonIndex, String? animationName) async {
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

    print('📤 Sending animation for Button ${_getButtonLabel(buttonIndex)}: ${animation.name}');
    
    // Kirim frame data untuk setiap channel (A-J)
    await _sendAnimationFrames(buttonIndex, animation);
    
    // Kirim delay data
    await _sendAnimationDelay(buttonIndex, animation);
    
    print('✅ Successfully sent animation for Button ${_getButtonLabel(buttonIndex)}');
  }

  // Method _sendAnimationFrames, _getDeviceChannelCount, _calculateFramesPerChannel, 
  // _extractChannelDataForDevice, _getFrameDataForChannelFrame, _extractChannelData
  // tetap sama seperti sebelumnya...

  Future<void> _sendAnimationFrames(int buttonIndex, AnimationModel animation) async {
    final deviceChannelCount = await _getDeviceChannelCount();
    final framesPerChannel = _calculateFramesPerChannel(deviceChannelCount);
    
    print('📊 Device Channels: $deviceChannelCount, Frames per Channel: $framesPerChannel');

    for (int channel = 0; channel < deviceChannelCount; channel++) {
      final channelLetter = String.fromCharCode(65 + channel); // A, B, C, ...
      if (channelLetter.codeUnitAt(0) > 74) break; // Hanya sampai J
      
      // Extract data untuk channel ini dari semua frames
      final channelData = _extractChannelDataForDevice(animation, channel, deviceChannelCount);
      
      if (channelData.isNotEmpty) {
        // Kirim data per frame
        for (int frameIndex = 0; frameIndex < framesPerChannel; frameIndex++) {
          final frameData = _getFrameDataForChannelFrame(channelData, frameIndex, framesPerChannel);
          if (frameData.isNotEmpty) {
            // Format: M[buttonIndex][channelLetter][frameIndex][dataLength][hexData]
            widget.socketService.uploadAnimation(
              remoteIndex: buttonIndex,
              channel: channelLetter,
              frameIndex: frameIndex + 1, // Start from frame 1
              hexData: frameData,
            );
            
            print('📤 Sent Button ${_getButtonLabel(buttonIndex)} - Channel $channelLetter - Frame ${frameIndex + 1}: $frameData');
            
            // Delay kecil antara pengiriman frame
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }
      }
    }
  }

  Future<int> _getDeviceChannelCount() async {
    try {
      final settings = await _firebaseService.getUserSetting('device_config');
      if (settings != null && settings['channelCount'] != null) {
        return settings['channelCount'] as int;
      }
    } catch (e) {
      print('❌ Error getting device channel count: $e');
    }
    return 8; // Default fallback
  }

  int _calculateFramesPerChannel(int deviceChannelCount) {
    if (deviceChannelCount <= 8) return 1;
    if (deviceChannelCount <= 16) return 2;
    if (deviceChannelCount <= 24) return 3;
    return 4; // Untuk 32 channels
  }

  String _extractChannelDataForDevice(AnimationModel animation, int channelIndex, int deviceChannelCount) {
    final buffer = StringBuffer();
    final framesPerChannel = _calculateFramesPerChannel(deviceChannelCount);
    
    for (final frame in animation.frameData) {
      for (int frameOffset = 0; frameOffset < framesPerChannel; frameOffset++) {
        final actualChannelIndex = channelIndex + (frameOffset * 8);
        if (actualChannelIndex < deviceChannelCount) {
          final hexPosition = actualChannelIndex * 2;
          if (hexPosition + 2 <= frame.length) {
            buffer.write(frame.substring(hexPosition, hexPosition + 2));
          } else {
            buffer.write('00'); // Padding jika data tidak cukup
          }
        }
      }
    }
    
    return buffer.toString();
  }

  String _getFrameDataForChannelFrame(String channelData, int frameIndex, int framesPerChannel) {
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
  Future<void> _sendAnimationDelay(int buttonIndex, AnimationModel animation) async {
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

  // Helper methods
  String _getButtonLabel(int buttonIndex) {
    switch (buttonIndex) {
      case 1: return 'A';
      case 2: return 'B';
      case 3: return 'C';
      case 4: return 'D';
      default: return '?';
    }
  }

  String _getDelayType(int buttonIndex) {
    switch (buttonIndex) {
      case 1: return 'K';
      case 2: return 'L';
      case 3: return 'M';
      case 4: return 'N';
      default: return 'K';
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
                          border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
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
                      _buildMappingItem(
                        label: 'TOMBOL A :',
                        selectedValue: _selectedAnimationA,
                        onChanged: (value) {
                          setState(() {
                            _selectedAnimationA = value;
                          });
                          _saveMappings();
                        },
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
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Tombol KIRIM SEMUA
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_allAnimations.isEmpty || !widget.socketService.isConnected || _isSending) 
                      ? null 
                      : _sendAllAnimations,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_allAnimations.isEmpty || !widget.socketService.isConnected)
                        ? AppColors.neonGreen.withOpacity(0.3)
                        : AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSending
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlack,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('MENGIRIM...'),
                          ],
                        )
                      : const Text(
                          'KIRIM SEMUA KE DEVICE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          
              // Info Panel
              if (_allAnimations.isNotEmpty) ...[
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
        Icon(
          Icons.info,
          color: AppColors.neonGreen,
          size: 16,
        ),
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
  }) {
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
          // Label tombol
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Dropdown animasi
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
                underline: const SizedBox(), // Remove default underline
                icon: Icon(Icons.arrow_drop_down, color: AppColors.neonGreen),
                hint: Text(
                  'Pilih Animasi',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                items: _buildDropdownItems(),
                onChanged: onChanged,
              ),
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
        ),
      ),
    ];

    // Add default animations FIRST dengan label khusus
    items.addAll(_defaultAnimations.map((animation) {
      return DropdownMenuItem<String>(
        value: animation.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  animation.name,
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontWeight: FontWeight.bold,
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
            ),
          ],
        ),
      );
    }).toList());

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
    items.addAll(_userAnimations.map((animation) {
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
            ),
            Text(
              '${animation.channelCount}C • ${animation.animationLength}L • ${animation.totalFrames}F',
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
    }).toList());

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

    final isDefault = _defaultAnimations.any((anim) => anim.name == animationName);

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
            ),
          ),
          if (animationName != null && animation.name.isNotEmpty)
            Expanded(
              child: Row(
                children: [
                  Text(
                    animationName,
                    style: TextStyle(
                      color: isDefault ? Colors.blue : AppColors.neonGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isDefault) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'D',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.animationLength}L',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${animation.totalFrames}F',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Not assigned',
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
}