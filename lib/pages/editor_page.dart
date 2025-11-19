// pages/editor_page.dart
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/animation_service.dart';
import 'package:iTen/services/firebase_data_service.dart'; // TAMBAH INI
import 'package:iTen/services/matrix_pattern_service.dart';
import 'package:iTen/services/preferences_service.dart';

class EditorPage extends StatefulWidget {
  final AnimationModel? initialAnimation;
  final Function(AnimationModel)? onSave;

  const EditorPage({super.key, this.initialAnimation, this.onSave});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final AnimationService _animationService = AnimationService();
  final MatrixPatternService _patternService = MatrixPatternService();
  final PreferencesService _preferencesService = PreferencesService();
    final FirebaseDataService _firebaseService = FirebaseDataService();
  late ConfigModel? config;

  // Data animasi
  int _channelCount = 0;
  int _animationLength = 0;
  late String _description;
  String _delayData = "4";
  late List<String> _frameData;
  List<String> _frameDataHex = List<String>.filled(11, '');
  List<String> _listAnim = List<String>.filled(11, '');
  // State management
  int _currentFrame = 0;
  bool _isPlaying = false;
  int _playSpeed = 500;
  bool _isSavingToCloud = false;
  bool _saveToCloud = true;
    bool _isLoading = true;

  // UI controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _channelController = TextEditingController();

  // Scroll controllers
  final ScrollController _frameScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _preferencesService.getDeviceConfig().then((configValue) {
      setState(() {
        config = configValue;
        _initializeFromExistingOrNew();
      });
    });
  }

  void _initializeFromExistingOrNew() {
    // if (widget.initialAnimation != null) {
    //   final anim = widget.initialAnimation!;
    //   _channelCount = anim.channelCount;
    //   _animationLength = anim.animationLength;
    //   _description = anim.description;
    //   _delayData = anim.delayData;
    //   _frameData = List.from(anim.frameData);

    //   // Initialize _listAnim dari frameData yang ada
    //   _initializeListAnimFromFrameData();

    //   _nameController.text = anim.name;
    //   _descController.text = anim.description;
    //   _channelController.text = (config?.jumlahChannel ?? 8).toString();
    // } else {
    _channelCount = config?.jumlahChannel ?? 8;
    _animationLength = 1;
    _description = '';
    _delayData = '4';
    _frameData = ['0' * (_channelCount * 2)];

    // Initialize _listAnim dengan data kosong
    _initializeEmptyListAnim();

    _nameController.text = '';
    _descController.text = '';
    _channelController.text = _channelCount.toString();
    // }
  }

  void _initializeListAnimFromFrameData() {
    // Reset _listAnim
    _listAnim = List<String>.filled(11, '');

    // Convert setiap frame ke format _listAnim
    for (int frameIndex = 0; frameIndex < _frameData.length; frameIndex++) {
      List<dynamic> hexData = _animationService.frameToHex(
        _frameData[frameIndex],
        _channelCount,
      );

      // Update setiap channel group di _listAnim
      for (int i = 0; i < hexData.length; i++) {
        final start = frameIndex * 2;
        final end = start + 2;

        if (_listAnim[i].length < end) {
          _listAnim[i] = _listAnim[i].padRight(end, '0');
        }

        _listAnim[i] = _replaceRange(_listAnim[i], start, end, hexData[i]);
      }
    }
  }

  void _initializeEmptyListAnim() {
    // Initialize dengan string kosong sepanjang yang dibutuhkan
    for (int i = 0; i < _listAnim.length; i++) {
      _listAnim[i] = '';
    }
  }

  void _loadUserPreferences() async {
    await _animationService.initialize();
    final lastChannel = config?.jumlahChannel ?? 8;
    setState(() {
      _channelCount = lastChannel;
      _channelController.text = lastChannel.toString();
      _updateFrameDataStructure();
    });
  }

  List<String> _convertFramesToHexFormat(
    List<String> frameData,
    int channelCount,
  ) {
    return frameData.map((frame) {
      final hexList = _animationService.frameToHex(frame, channelCount);
      return hexList.join(); // Gabungkan semua hex menjadi satu string
    }).toList();
  }

  void _updateFrameDataStructure() {
    setState(() {
      _frameData = _animationService.updateFrameDataStructure(
        _frameData,
        _channelCount,
      );
      // Update juga frameDataHex
      // _frameDataHex = _convertFramesToHexFormat(_frameData, _channelCount);
    });
  }

  void _updateChannelCount() {
    final newCount = int.tryParse(_channelController.text) ?? _channelCount;
    if (newCount >= 4 && newCount <= 32) {
      setState(() {
        _channelCount = newCount;
        _animationService.saveLastSelectedChannel(newCount);
        _updateFrameDataStructure();
      });
    }
  }

  // ============ FRAME MANAGEMENT METHODS ============

  // ============ FRAME MANAGEMENT METHODS ============

  void _addFrame() {
    setState(() {
      _animationLength++;
      _delayData = _delayData.padRight(_animationLength, '4');
      _frameData = _patternService.addFrame(
        _frameData,
        _delayData,
        _animationLength,
        _channelCount,
      );
      // Update _listAnim untuk frame baru
      _updateListAnimForNewFrame(_animationLength - 1);
      _currentFrame = _animationLength - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _frameScrollController.animateTo(
          _frameScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _updateListAnimForNewFrame(int frameIndex) {
    List<dynamic> hexData = _animationService.frameToHex(
      _frameData[frameIndex],
      _channelCount,
    );

    for (int i = 0; i < hexData.length; i++) {
      final start = frameIndex * 2;
      final end = start + 2;

      if (_listAnim[i].length < end) {
        _listAnim[i] = _listAnim[i].padRight(end, '0');
      }

      _listAnim[i] = _replaceRange(_listAnim[i], start, end, hexData[i]);
    }
  }

  void _removeFrame(int index) {
    if (_animationLength <= 1) return;

    setState(() {
      _animationLength--;
      _frameData = _patternService.removeFrame(_frameData, _delayData, index);
      _delayData =
          _delayData.substring(0, index) + _delayData.substring(index + 1);

      // Update _listAnim - hapus data frame yang dihapus
      _removeFrameFromListAnim(index);

      if (_currentFrame >= _animationLength) {
        _currentFrame = _animationLength - 1;
      }
    });
  }

  void _removeFrameFromListAnim(int frameIndex) {
    for (int i = 0; i < _listAnim.length; i++) {
      final start = frameIndex * 2;
      final end = start + 2;

      if (_listAnim[i].length >= end) {
        _listAnim[i] =
            _listAnim[i].substring(0, start) + _listAnim[i].substring(end);
      }
    }
  }

  void _duplicateFrame(int index) {
    setState(() {
      _animationLength++;
      _frameData = _patternService.duplicateFrame(
        _frameData,
        _delayData,
        index,
      );

      _delayData =
          _delayData.substring(0, index + 1) +
          _delayData[index] +
          _delayData.substring(index + 1);

      // Update _listAnim - duplicate frame
      _currentFrame = index + 1;
      _duplicateFrameInListAnim(index);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // --- INI DIA TAMBAHANNYA ---
        // Perintahkan Flutter untuk melepas fokus dari widget manapun
        FocusScope.of(context).unfocus();
        // --- SELESAI ---
        // Lebar item (70) + margin horizontal (4*2 = 8) = 78
        final itemWidth = 78.0;
        final newOffset = _currentFrame * itemWidth;

        _frameScrollController.animateTo(
          newOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _duplicateFrameInListAnim(int frameIndex) {
    for (int i = 0; i < _listAnim.length; i++) {
      final start = frameIndex * 2;
      final end = start + 2;

      String frameData = '';

      // Cek apakah string cukup panjang untuk diakses
      if (_listAnim[i].length >= end) {
        frameData = _listAnim[i].substring(start, end);
      } else if (_listAnim[i].length > start) {
        // Jika string lebih panjang dari start tapi kurang dari end
        frameData = _listAnim[i].substring(start).padRight(2, '0');
      } else {
        // Jika string terlalu pendek, gunakan default
        frameData = '00';
      }

      // Pastikan _listAnim[i] cukup panjang sebelum insert
      int requiredLength = start + 2;
      if (_listAnim[i].length < requiredLength) {
        _listAnim[i] = _listAnim[i].padRight(requiredLength, '0');
      }

      // Insert duplicate data
      _listAnim[i] =
          _listAnim[i].substring(0, start + 2) +
          frameData +
          _listAnim[i].substring(start + 2);
    }
  }

  void _clearFrame(int index) {
    setState(() {
      _frameData[index] = '0' * (_channelCount * 2);

      // Update _listAnim - clear frame
      _clearFrameInListAnim(index);
    });
  }

  void _clearFrameInListAnim(int frameIndex) {
    List<dynamic> hexData = _animationService.frameToHex(
      '0' * (_channelCount * 2), // Frame kosong
      _channelCount,
    );

    for (int i = 0; i < hexData.length; i++) {
      final start = frameIndex * 2;
      final end = start + 2;

      if (_listAnim[i].length < end) {
        _listAnim[i] = _listAnim[i].padRight(end, '0');
      }

      _listAnim[i] = _replaceRange(_listAnim[i], start, end, hexData[i]);
    }
  }

  String _replaceRange(String source, int start, int end, String replacement) {
    if (source.length < end) {
      source = source.padRight(end, '0');
    }
    return source.substring(0, start) + replacement + source.substring(end);
  }

  // ============ MATRIX EDITOR METHODS ============

  void _toggleLED(int channel, int frameIndex) {
    print('=== TOGGLE LED TRACE ===');
    print('Frame Index: $frameIndex');
    print('Channel Clicked: ${channel + 1} (1-based) / $channel (0-based)');
    print('Total Channels: $_channelCount');
    print('Current Frame Data: ${_frameData[frameIndex]}');
    print('Current Frame Hex: ${_frameDataHex[frameIndex]}');

    setState(() {
      _frameData[frameIndex] = _animationService.toggleLED(
        _frameData[frameIndex],
        channel,
        _channelCount,
      );

      List<dynamic> hexDat = _animationService.frameToHex(
        _frameData[frameIndex],
        _channelCount,
      );

      print('After Toggle - Frame Data (raw hex): $hexDat');
      print('delay data is: $_delayData');

      // Update setiap channel
      for (int i = 0; i < hexDat.length; i++) {
        final start = frameIndex * 2;
        final end = start + 2;

        // Pastikan string cukup panjang dulu
        if (_listAnim[i].length < end) {
          _listAnim[i] = _listAnim[i].padRight(end, '0');
        }

        _listAnim[i] = replaceRange(_listAnim[i], start, end, hexDat[i]);
      }
    });

    print('After Toggle - Frame Data (updated): ${_listAnim.toString()}');
    print('=======================\n');
  }

  String replaceRange(String source, int start, int end, String replacement) {
    if (source.length < end) {
      source = source.padRight(end, '0'); // biar gak error
    }
    return source.substring(0, start) + replacement + source.substring(end);
  }

  bool _isLEDOn(int channel, int frameIndex) {
    return _animationService.isLEDOn(
      _frameData[frameIndex],
      channel,
      _channelCount,
    );
  }

  void _setDelayForFrame(int frameIndex, String delay) {
    setState(() {
      _delayData = _patternService.updateDelayForFrame(
        _delayData,
        frameIndex,
        delay,
      );
    });
  }

  // ============ ANIMATION PLAYBACK METHODS ============

  void _playPauseAnimation() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    if (!_isPlaying) return;

    Future.delayed(Duration(milliseconds: _playSpeed), () {
      if (mounted && _isPlaying) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _animationLength;
        });
        _playAnimation();
      }
    });
  }

  void _stopAnimation() {
    setState(() {
      _isPlaying = false;
      _currentFrame = 0;
    });
  }

  void _setPlaySpeed(int speed) {
    setState(() {
      _playSpeed = speed;
    });
  }

  // ============ SAVE/LOAD METHODS ============
// Di _saveAnimation method - perbaiki bagian ini:

void _saveAnimation() async {
  final name = _nameController.text.trim();
  if (name.isEmpty) {
    _showError('Please enter animation name');
    return;
  }

  print('=== SAVING ANIMATION ===');
  print('ListAnim Data: $_listAnim');
  print('Channel Count: $_channelCount');
  print('Animation Length: $_animationLength');

  // DEBUG: Print untuk troubleshooting
  print('🔄 DEBUG: Preparing animation data...');
  for (int i = 0; i < _listAnim.length; i++) {
    print('   - _listAnim[$i]: "${_listAnim[i]}" (length: ${_listAnim[i].length})');
  }

  // Convert _listAnim ke format yang sesuai untuk disimpan
  List<String> formattedFrameData = [];
  for (int i = 0; i < _listAnim.length; i++) {
    String frame = _listAnim[i];
    
    // Pastikan frame data memiliki panjang yang benar
    if (frame.isEmpty) {
      frame = "00" * _animationLength;
      print('   ⚠️ Empty frame[$i], setting to: "$frame"');
    } else if (frame.length < _animationLength * 2) {
      // Padding dengan '00' jika terlalu pendek
      frame = frame.padRight(_animationLength * 2, '0');
      print('   ⚠️ Short frame[$i], padding to: "$frame"');
    } else if (frame.length > _animationLength * 2) {
      // Potong jika terlalu panjang
      frame = frame.substring(0, _animationLength * 2);
      print('   ⚠️ Long frame[$i], truncating to: "$frame"');
    }
    
    formattedFrameData.add(frame);
  }

  print('✅ Formatted Frame Data:');
  for (int i = 0; i < formattedFrameData.length; i++) {
    print('   - frameData[$i]: "${formattedFrameData[i]}" (length: ${formattedFrameData[i].length})');
  }

  // Pastikan delay data sesuai dengan animation length
  String formattedDelayData = _delayData;
  if (_delayData.length < _animationLength) {
    formattedDelayData = _delayData.padRight(_animationLength, '4');
    print('⚠️ Delay data too short, padding to: "$formattedDelayData"');
  } else if (_delayData.length > _animationLength) {
    formattedDelayData = _delayData.substring(0, _animationLength);
    print('⚠️ Delay data too long, truncating to: "$formattedDelayData"');
  }

  final animation = AnimationModel(
    name: name,
    channelCount: _channelCount,
    animationLength: _animationLength,
    description: _descController.text.trim(),
    delayData: formattedDelayData,
    frameData: formattedFrameData,
  );

  // DEBUG: Validasi manual sebelum menggunakan animation.isValid
  print('🔍 DEBUG: Manual validation check:');
  print('   - Name: ${animation.name.isNotEmpty}');
  print('   - Channel Count: ${animation.channelCount >= 4 && animation.channelCount <= 32}');
  print('   - Animation Length: ${animation.animationLength > 0}');
  print('   - Delay Data Length: ${animation.delayData.length == animation.animationLength}');
  print('   - Frame Data Length: ${animation.frameData.length == 11}'); // Harus 11 channels
  
  bool allFramesValid = true;
  for (int i = 0; i < animation.frameData.length; i++) {
    bool frameValid = animation.frameData[i].length == animation.animationLength * 2;
    print('   - Frame[$i] valid: $frameValid (length: ${animation.frameData[i].length}, expected: ${animation.animationLength * 2})');
    if (!frameValid) {
      allFramesValid = false;
    }
  }

  if (!animation.isValid) {
    print('❌ ANIMATION VALIDATION FAILED:');
    print('   - isValid: ${animation.isValid}');
    print('   - Manual check: ${allFramesValid && animation.delayData.length == animation.animationLength}');
    
    _showError('Animation data is not valid. Please check frame data.');
    return;
  }

  print('✅ ANIMATION VALIDATION PASSED');

  // Simpan ke local storage terlebih dahulu
  final selectedAnimationKey = _animationService.generateAnimationKey(
    name,
    _channelCount,
    config?.email ?? "CC",
  );

  await _animationService.saveToSelectedAnimations(
    selectedAnimationKey,
    animation,
  );
  _animationService.addUserSelectedAnimation(animation);

  // Jika save ke cloud, tampilkan konfirmasi
  if (_saveToCloud) {
    final cloudEmail = await _firebaseService.getCloudEmail();
    _showCloudSaveConfirmation(animation, cloudEmail);
  } else {
    _showSuccess('Animation "$name" saved to device!');
    widget.onSave?.call(animation);
  }
}
  Widget _buildSaveOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? AppColors.neonGreen.withOpacity(0.2) : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.neonGreen : AppColors.darkGrey,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: value ? AppColors.neonGreen : AppColors.darkGrey,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: value ? AppColors.primaryBlack : AppColors.pureWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.pureWhite.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: value,
              onChanged: (bool? newValue) => onChanged(newValue ?? false),
              fillColor: MaterialStateProperty.all(AppColors.neonGreen),
            ),
          ],
        ),
      ),
    );
  }
  void _clearAllFrames() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text(
          'Clear All Frames',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: const Text(
          'Are you sure you want to clear all animation frames?',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.neonGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _frameData = List.generate(
                  _animationLength,
                  (_) => '0' * (_channelCount * 2),
                );
                // Clear _listAnim juga
                _initializeEmptyListAnim();
                _currentFrame = 0;
                _isPlaying = false;
              });
              Navigator.pop(context);
              _showSuccess('All frames cleared');
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  // ============ UI HELPER METHODS ============

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.errorRed,
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.successGreen,
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============ BUILD METHODS ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildAnimationPreview(),
                      const SizedBox(height: 16),
                      _buildFrameManagement(),
                      const SizedBox(height: 16),
                      _buildMatrixEditor(),
                      const SizedBox(height: 16),
                      _buildBottomControls(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ... (All the UI build methods remain exactly the same as in your original code)
  // _buildHeader(), _buildAnimationPreview(), _buildFrameManagement(),
  // _buildMatrixEditor(), _buildFrameItem(), _buildPerfectXGrid(),
  // _buildPerfectXLED(), _buildDelayControl(), _buildBottomControls()

  // These methods can remain exactly the same since they only handle UI rendering
  Widget _buildHeader() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.pureWhite),
                    decoration: InputDecoration(
                      labelText: 'Animation Name',
                      labelStyle: TextStyle(color: AppColors.neonGreen),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _channelController,
                    style: const TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateChannelCount(),
                    decoration: InputDecoration(
                      labelText: 'Channels',
                      labelStyle: TextStyle(color: AppColors.neonGreen),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppColors.neonGreen),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.neonGreen),
                ),
              ),
              onChanged: (value) => _description = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationPreview() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Animation Preview',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Frames: $_animationLength',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonGreen),
                    ),
                    child: Center(
                      child: Text(
                        'Frame ${_currentFrame + 1}/$_animationLength',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      onPressed: _playPauseAnimation,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppColors.neonGreen,
                        size: 30,
                      ),
                    ),
                    IconButton(
                      onPressed: _stopAnimation,
                      icon: Icon(
                        Icons.stop,
                        color: AppColors.errorRed,
                        size: 30,
                      ),
                    ),
                    PopupMenuButton<int>(
                      icon: Icon(
                        Icons.speed,
                        color: AppColors.neonGreen,
                        size: 30,
                      ),
                      onSelected: _setPlaySpeed,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1000,
                          child: Text(
                            'Slow (1s)',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ),
                        PopupMenuItem(
                          value: 500,
                          child: Text(
                            'Medium (500ms)',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ),
                        PopupMenuItem(
                          value: 200,
                          child: Text(
                            'Fast (200ms)',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameManagement() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Frame Management',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addFrame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Frame'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Scrollbar(
                controller: _frameScrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _frameScrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: _animationLength,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentFrame;
                    return _buildFrameItem(index, isSelected);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameItem(int index, bool isSelected) {
    final delay = _delayData.length > index ? _delayData[index] : '4';

    return Container(
      width: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _currentFrame = index;
                _isPlaying = false;
              });
            },
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.neonGreen
                    : AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.neonGreen : AppColors.darkGrey,
                  width: 2,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primaryBlack
                            : AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    Positioned(
                      top: 2,
                      right: 2,
                      child: PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 16,
                          color: AppColors.primaryBlack,
                        ),
                        onSelected: (action) {
                          switch (action) {
                            case 'duplicate':
                              _duplicateFrame(index);
                              break;
                            case 'clear':
                              _clearFrame(index);
                              break;
                            case 'delete':
                              _removeFrame(index);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text(
                              'Duplicate',
                              style: TextStyle(color: AppColors.pureWhite),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'clear',
                            child: Text(
                              'Clear Frame',
                              style: TextStyle(color: AppColors.pureWhite),
                            ),
                          ),
                          if (_animationLength > 1)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete Frame',
                                style: TextStyle(color: AppColors.errorRed),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.neonGreen),
            ),
            child: Text(
              'D: $delay',
              style: TextStyle(color: AppColors.neonGreen, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixEditor() {
    final displayFrame = _isPlaying ? _currentFrame : _currentFrame;
    final gridSize = _patternService.calculateOptimalGridSize(_channelCount);
    final availableHeight = MediaQuery.of(context).size.height * 0.4;

    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frame ${displayFrame + 1} Editor',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDelayControl(displayFrame),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: availableHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: Scrollbar(
                  thumbVisibility: true,
                  notificationPredicate: (notification) =>
                      notification.depth == 1,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: _buildPerfectXGrid(displayFrame, gridSize),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfectXGrid(int frameIndex, int gridSize) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          for (int row = 0; row < gridSize; row++)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int col = 0; col < gridSize; col++)
                  _buildPerfectXLED(row, col, gridSize, frameIndex),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPerfectXLED(int row, int col, int gridSize, int frameIndex) {
    final channelInfo = _patternService.getChannelForPerfectX(
      row,
      col,
      gridSize,
      _channelCount,
    );
    final channel = channelInfo['channel'];
    final isValid = channelInfo['isValid'];

    if (!isValid) {
      return Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: AppColors.darkGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final isOn = _isLEDOn(channel, frameIndex);
    final displayNumber = channel + 1;

    return GestureDetector(
      onTap: () => _toggleLED(channel, frameIndex),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isOn ? AppColors.neonGreen : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.neonGreen.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.9),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$displayNumber',
            style: TextStyle(
              color: isOn ? AppColors.primaryBlack : AppColors.pureWhite,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelayControl(int frameIndex) {
    final currentDelay = frameIndex < _delayData.length
        ? _delayData[frameIndex]
        : '4';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Delay:',
            style: TextStyle(color: AppColors.pureWhite, fontSize: 12),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: currentDelay,
            dropdownColor: AppColors.darkGrey,
            style: const TextStyle(color: AppColors.pureWhite, fontSize: 12),
            onChanged: (value) => _setDelayForFrame(frameIndex, value!),
            items: ['1', '2', '3', '4'].map((delay) {
              return DropdownMenuItem(
                value: delay,
                child: Text(
                  '$delay',
                  style: TextStyle(color: AppColors.pureWhite),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

 Widget _buildBottomControls() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Info Section dengan styling matrix
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoItem('CHANNELS', '$_channelCount', Icons.cable),
                  _buildInfoItem(
                    'FRAMES',
                    '$_animationLength',
                    Icons.video_label,
                  ),
                  _buildInfoItem(
                    'TOTAL LEDs',
                    '${_channelCount * _animationLength}',
                    Icons.lightbulb,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons Section dengan styling modern
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clear Button
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withOpacity(0.8),
                          Colors.red.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _clearAllFrames,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.pureWhite,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: const Icon(Icons.delete_sweep, size: 20),
                      label: const Text(
                        'CLEAR',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Save Button - MODIFIKASI: panggil _showSaveOptions
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonGreen.withOpacity(0.9),
                          AppColors.neonGreen.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGreen.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSavingToCloud ? null : _showSaveOptions, // MODIFIKASI INI
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.primaryBlack,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      icon: _isSavingToCloud 
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlack,
                              ),
                            )
                          : const Icon(Icons.save_alt, size: 20),
                      label: _isSavingToCloud 
                          ? const Text(
                              'SAVING...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            )
                          : const Text(
                              'SAVE',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),

            // TAMBAH: Cloud save status indicator
            if (_isSavingToCloud) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: AppColors.neonGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Uploading to cloud...',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  // Helper widget untuk info item
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neonGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
          ),
          child: Icon(icon, color: AppColors.neonGreen, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: AppColors.neonGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

void _showCloudSaveConfirmation(AnimationModel animation, String cloudEmail) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Row(
        children: [
          Icon(Icons.cloud_upload, color: AppColors.neonGreen),
          SizedBox(width: 8),
          Text(
            'Save to Cloud',
            style: TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save "${animation.name}" to cloud storage?',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Format:',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '[Channel] [Animation Name] [Email]',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Example: "${animation.channelCount.toString().padLeft(3, '0')} ${animation.name} $cloudEmail"',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email, color: AppColors.neonGreen, size: 16),
              SizedBox(width: 4),
              Text(
                'Using identifier: $cloudEmail',
                style: TextStyle(
                  color: AppColors.pureWhite.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (cloudEmail == 'CC') ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 14),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Using "CC" as identifier. Configure device to use your email.',
                      style: TextStyle(color: Colors.blue, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: AppColors.neonGreen)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _performCloudSave(animation);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.neonGreen,
            foregroundColor: AppColors.primaryBlack,
          ),
          child: Text('SAVE TO CLOUD'),
        ),
      ],
    ),
  );
}

// Method untuk save single animation ke cloud
Future<void> _performCloudSave(AnimationModel animation) async {
  setState(() {
    _isSavingToCloud = true;
  });

  try {
    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.neonGreen),
            SizedBox(height: 16),
            Text(
              'Saving "${animation.name}" to cloud...',
              style: TextStyle(color: AppColors.pureWhite),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            FutureBuilder(
              future: _firebaseService.getCloudEmail(),
              builder: (context, snapshot) {
                final email = snapshot.data ?? 'CC';
                return Text(
                  'Using identifier: $email',
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ],
        ),
      ),
    );

    // Save single animation to cloud
    final success = await _firebaseService.saveAnimationToCloud(animation);

    // Close progress dialog
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (success) {
      _showCloudSaveSuccess(animation);
    } else {
      throw Exception('Failed to save animation to cloud');
    }

  } catch (e) {
    // Close progress dialog if open
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    _showCloudSaveError(animation.name, e.toString());
  } finally {
    setState(() {
      _isSavingToCloud = false;
    });
  }
}

// Method untuk show success result
void _showCloudSaveSuccess(AnimationModel animation) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.neonGreen),
          SizedBox(width: 8),
          Text(
            'Success!',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Animation "${animation.name}" saved to cloud successfully!',
            style: TextStyle(color: AppColors.pureWhite),
          ),
          SizedBox(height: 12),
          FutureBuilder(
            future: _firebaseService.getCloudEmail(),
            builder: (context, snapshot) {
              final email = snapshot.data ?? 'CC';
              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stored as:',
                      style: TextStyle(
                        color: AppColors.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${animation.channelCount.toString().padLeft(3, '0')} ${animation.name} $email',
                      style: TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppColors.neonGreen)),
        ),
      ],
    ),
  );
}

// Method untuk show error result
void _showCloudSaveError(String animationName, String error) {
  String errorMessage = 'Failed to save to cloud';
  
  if (error.contains('already exists')) {
    errorMessage = 'Animation "$animationName" already exists in cloud storage';
  } else if (error.contains('No internet')) {
    errorMessage = 'No internet connection - cannot save to cloud';
  } else {
    errorMessage = 'Failed to save to cloud: $error';
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.darkGrey,
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 8),
          Text(
            'Save Failed',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        errorMessage,
        style: TextStyle(color: AppColors.pureWhite),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK', style: TextStyle(color: AppColors.neonGreen)),
        ),
      ],
    ),
  );
}

void _showSaveOptions() {
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: AppColors.darkGrey,
          title: Text(
            'Save Animation',
            style: TextStyle(
              color: AppColors.neonGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose where to save "${_nameController.text.trim()}"',
                style: TextStyle(color: AppColors.pureWhite),
              ),
              const SizedBox(height: 16),
              
              // Local storage option
              _buildSaveOption(
                title: 'Local Storage Only',
                subtitle: 'Save to device only',
                icon: Icons.storage,
                value: !_saveToCloud,
                onChanged: (value) {
                  setDialogState(() {
                    _saveToCloud = !value;
                  });
                },
              ),
              
              const SizedBox(height: 12),
              
              // Cloud storage option
              _buildSaveOption(
                title: 'Cloud Storage',
                subtitle: 'Save to device and cloud',
                icon: Icons.cloud_upload,
                value: _saveToCloud,
                onChanged: (value) {
                  setDialogState(() {
                    _saveToCloud = value;
                  });
                },
              ),
              
              if (_saveToCloud) ...[
                const SizedBox(height: 12),
                FutureBuilder(
                  future: _firebaseService.getCloudEmail(),
                  builder: (context, snapshot) {
                    final email = snapshot.data ?? 'CC';
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neonGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: AppColors.neonGreen, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Cloud Storage Info',
                                style: TextStyle(
                                  color: AppColors.neonGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            '• Will be available on all your devices',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '• Stored as: ${_channelCount.toString().padLeft(3, '0')} ${_nameController.text.trim()} $email',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: TextStyle(color: AppColors.pureWhite),
              ),
            ),
            ElevatedButton(
              onPressed: _isSavingToCloud ? null : () {
                Navigator.pop(context);
                _saveAnimation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: AppColors.primaryBlack,
              ),
              child: _isSavingToCloud 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryBlack,
                      ),
                    )
                  : Text('SAVE'),
            ),
          ],
        );
      },
    ),
  );
  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _channelController.dispose();
    _frameScrollController.dispose();
    super.dispose();
  }
}
}