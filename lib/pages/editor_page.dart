// pages/editor_page.dart
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/animation_model.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/animation_service.dart';
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
  late ConfigModel? config;

  // Data animasi
  int _channelCount = 0;
  int _animationLength = 0;
  String _description = '';
  String _delayData = "4";
  late List<String> _frameData;
  List<String> _frameDataHex = List<String>.filled(11, '');
  List<String> _listAnim = List<String>.filled(11, '');
  
  // State management
  int _currentFrame = 0;
  bool _isPlaying = false;
  int _playSpeed = 500;
  bool _isSaving = false;
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
        _isLoading = false;
      });
    });
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
      return hexList.join();
    }).toList();
  }

  void _updateFrameDataStructure() {
    setState(() {
      _frameData = _animationService.updateFrameDataStructure(
        _frameData,
        _channelCount,
      );
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
        FocusScope.of(context).unfocus();
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

      if (_listAnim[i].length >= end) {
        frameData = _listAnim[i].substring(start, end);
      } else if (_listAnim[i].length > start) {
        frameData = _listAnim[i].substring(start).padRight(2, '0');
      } else {
        frameData = '00';
      }

      int requiredLength = start + 2;
      if (_listAnim[i].length < requiredLength) {
        _listAnim[i] = _listAnim[i].padRight(requiredLength, '0');
      }

      _listAnim[i] =
          _listAnim[i].substring(0, start + 2) +
          frameData +
          _listAnim[i].substring(start + 2);
    }
  }

  void _clearFrame(int index) {
    setState(() {
      _frameData[index] = '0' * (_channelCount * 2);
      _clearFrameInListAnim(index);
    });
  }

  void _clearFrameInListAnim(int frameIndex) {
    List<dynamic> hexData = _animationService.frameToHex(
      '0' * (_channelCount * 2),
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

      for (int i = 0; i < hexDat.length; i++) {
        final start = frameIndex * 2;
        final end = start + 2;

        if (_listAnim[i].length < end) {
          _listAnim[i] = _listAnim[i].padRight(end, '0');
        }

        _listAnim[i] = _replaceRange(_listAnim[i], start, end, hexDat[i]);
      }
    });
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

    setState(() {
      _isSaving = true;
    });

    try {
      // Convert _listAnim ke format yang sesuai untuk disimpan
      List<String> formattedFrameData = [];
      for (int i = 0; i < _listAnim.length; i++) {
        String frame = _listAnim[i];
        
        if (frame.isEmpty) {
          frame = "00" * _animationLength;
        } else if (frame.length < _animationLength * 2) {
          frame = frame.padRight(_animationLength * 2, '0');
        } else if (frame.length > _animationLength * 2) {
          frame = frame.substring(0, _animationLength * 2);
        }
        
        formattedFrameData.add(frame);
      }

      // Pastikan delay data sesuai dengan animation length
      String formattedDelayData = _delayData;
      if (_delayData.length < _animationLength) {
        formattedDelayData = _delayData.padRight(_animationLength, '4');
      } else if (_delayData.length > _animationLength) {
        formattedDelayData = _delayData.substring(0, _animationLength);
      }

      final animation = AnimationModel(
        name: name,
        channelCount: _channelCount,
        animationLength: _animationLength,
        description: _descController.text.trim(),
        delayData: formattedDelayData,
        frameData: formattedFrameData,
      );

      if (!animation.isValid) {
        _showError('Animation data is not valid. Please check frame data.');
        return;
      }

      // Simpan ke local storage
      final selectedAnimationKey = _animationService.generateAnimationKey(
        name,
        _channelCount,
        "LOCAL",
      );

      await _animationService.saveToSelectedAnimations(
        selectedAnimationKey,
        animation,
      );
      _animationService.addUserSelectedAnimation(animation);

      _showSuccess('Animation "${animation.name}" saved to device!');
      widget.onSave?.call(animation);

    } catch (e) {
      _showError('Failed to save animation: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
                _initializeEmptyListAnim();
                _currentFrame = 0;
                _isPlaying = false;
              });
              Navigator.pop(context);
              _showSuccess('All frames cleared');
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
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
        backgroundColor: Colors.red,
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.pureWhite.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============ BUILD METHODS ============

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.neonGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
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
                      border: const OutlineInputBorder(),
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
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
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
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
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
                    color: Colors.red,
                    size: 30,
                  ),
                ),
                PopupMenuButton<int>(
                  icon: Icon(
                    Icons.speed,
                    color: AppColors.neonGreen,
                  ),
                  onSelected: _setPlaySpeed,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 1000,
                      child: Text('Slow (1s)'),
                    ),
                    PopupMenuItem(
                      value: 500,
                      child: Text('Medium (500ms)'),
                    ),
                    PopupMenuItem(
                      value: 200,
                      child: Text('Fast (200ms)'),
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
              child: ListView.builder(
                controller: _frameScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: _animationLength,
                itemBuilder: (context, index) {
                  return _buildFrameItem(index, index == _currentFrame);
                },
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
                color: isSelected ? AppColors.neonGreen : AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.neonGreen : AppColors.darkGrey,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 16, color: AppColors.primaryBlack),
                        onSelected: (action) {
                          switch (action) {
                            case 'duplicate':
                              _duplicateFrame(index);
                              break;
                            case 'clear':
                              _clearFrame(index);
                              break;
                            case 'delete':
                              if (_animationLength > 1) _removeFrame(index);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(
                            value: 'clear',
                            child: Text('Clear Frame'),
                          ),
                          if (_animationLength > 1)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Frame', style: TextStyle(color: Colors.red)),
                            ),
                        ],
                      ),
                    ),
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
                  'Frame ${_currentFrame + 1} Editor',
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDelayControl(_currentFrame),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: availableHeight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: _buildPerfectXGrid(_currentFrame, gridSize),
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
      );
    }

    final isOn = _isLEDOn(channel, frameIndex);

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
            color: AppColors.neonGreen,
            width: 2,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${channel + 1}',
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
    final currentDelay = _delayData.length > frameIndex ? _delayData[frameIndex] : '4';

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
                child: Text(delay),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
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
                  _buildInfoItem('FRAMES', '$_animationLength', Icons.video_label),
                  _buildInfoItem('TOTAL LEDs', '${_channelCount * _animationLength}', Icons.lightbulb),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearAllFrames,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: AppColors.pureWhite,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('CLEAR ALL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAnimation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonGreen,
                      foregroundColor: AppColors.primaryBlack,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: _isSaving 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryBlack,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: _isSaving ? const Text('SAVING...') : const Text('SAVE'),
                  ),
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