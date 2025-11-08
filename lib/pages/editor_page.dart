// pages/editor_page.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/animation_service.dart';
import 'package:ninexmano_matrix/services/matrix_pattern_service.dart';

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

  // Data animasi
  late int _channelCount;
  late int _animationLength;
  late String _description;
  late String _delayData;
  late List<String> _frameData;
  List<String> _frameDataHex = List<String>.filled(11, '');
  List<String> _listAnim = List<String>.filled(11, '');
  // State management
  int _currentFrame = 0;
  bool _isPlaying = false;
  int _playSpeed = 500;

  // UI controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _channelController = TextEditingController();

  // Scroll controllers
  final ScrollController _frameScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeFromExistingOrNew();
    _loadUserPreferences();
  }

  void _initializeFromExistingOrNew() {
    if (widget.initialAnimation != null) {
      final anim = widget.initialAnimation!;
      _channelCount = anim.channelCount;
      _animationLength = anim.animationLength;
      _description = anim.description;
      _delayData = anim.delayData;
      _frameData = List.from(anim.frameData);

      // Initialize _listAnim dari frameData yang ada
      _initializeListAnimFromFrameData();

      _nameController.text = anim.name;
      _descController.text = anim.description;
      _channelController.text = anim.channelCount.toString();
    } else {
      _channelCount = 80; // Default 80 channel
      _animationLength = 1;
      _description = '';
      _delayData = '4';
      _frameData = ['0' * (_channelCount * 2)];

      // Initialize _listAnim dengan data kosong
      _initializeEmptyListAnim();

      _nameController.text = '';
      _descController.text = '';
      _channelController.text = _channelCount.toString();
    }
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
    final lastChannel = await _animationService.getLastSelectedChannel();
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
      _duplicateFrameInListAnim(index);
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

    // Convert _listAnim ke format yang sesuai untuk disimpan
    for (int i = 0; i < _listAnim.length; i++) {
      if (_listAnim[i].isEmpty) {
        _listAnim[i] = ("00" * _animationLength);
      } else if (_listAnim[i].length < _animationLength * 2) {
        _listAnim[i] = ("00" * _animationLength);
      }
    }
    print('ListAnim after filter: $_listAnim');
    final animation = AnimationModel(
      name: name,
      channelCount: _channelCount,
      animationLength: _animationLength,
      description: _descController.text.trim(),
      delayData: _delayData,
      frameData: _listAnim,
    );

    if (!animation.isValid) {
      _showError('Animation data is not valid');
      return;
    }

    final selectedAnimationKey = _animationService.generateAnimationKey(
      name,
      _channelCount,
      "dimas@gmail.com",
    );

    await _animationService.saveToSelectedAnimations(
      selectedAnimationKey,
      animation,
    );
    _animationService.addUserSelectedAnimation(animation);

    widget.onSave?.call(animation);
    _showSuccess('Animation "$name" saved to selected animations!');
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
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channels: $_channelCount',
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
                Text(
                  'Frames: $_animationLength',
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
                Text(
                  'Total LEDs: ${_channelCount * _animationLength}',
                  style: const TextStyle(color: AppColors.pureWhite),
                ),
              ],
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _clearAllFrames,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: BorderSide(color: AppColors.errorRed),
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _saveAnimation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _channelController.dispose();
    _frameScrollController.dispose();
    super.dispose();
  }
}
