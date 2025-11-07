// pages/editor_page.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/animation_model.dart';
import 'package:ninexmano_matrix/services/preferences_service.dart';

class EditorPage extends StatefulWidget {
  final AnimationModel? initialAnimation;
  final Function(AnimationModel)? onSave;

  const EditorPage({
    super.key,
    this.initialAnimation,
    this.onSave,
  });

  @override
  State<EditorPage> createState() => _EditorPageState();
}
class Point {
  final int x;
  final int y;
  
  Point(this.x, this.y);
}
class _EditorPageState extends State<EditorPage> {
  final PreferencesService _prefsService = PreferencesService();
  
  // Data animasi
  late int _channelCount;
  late int _animationLength;
  late String _description;
  late String _delayData;
  late List<String> _frameData;
  
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
      
      _nameController.text = anim.name;
      _descController.text = anim.description;
      _channelController.text = anim.channelCount.toString();
    } else {
      _channelCount = 6;
      _animationLength = 1;
      _description = '';
      _delayData = '4';
      _frameData = ['0' * (_channelCount * 2)];
      
      _nameController.text = '';
      _descController.text = '';
      _channelController.text = _channelCount.toString();
    }
  }

  void _loadUserPreferences() async {
    await _prefsService.initialize();
    final lastChannel = await _prefsService.getLastSelectedChannel();
    setState(() {
      _channelCount = lastChannel;
      _channelController.text = lastChannel.toString();
      _updateFrameDataStructure();
    });
  }

  void _updateFrameDataStructure() {
    final hexLength = _channelCount * 2;
    
    _frameData = _frameData.map((frame) {
      if (frame.length > hexLength) {
        return frame.substring(0, hexLength);
      } else if (frame.length < hexLength) {
        return frame.padRight(hexLength, '0');
      }
      return frame;
    }).toList();
    
    setState(() {});
  }

  void _updateChannelCount() {
    final newCount = int.tryParse(_channelController.text) ?? _channelCount;
    if (newCount >= 4 && newCount <= 32) {
      setState(() {
        _channelCount = newCount;
        _prefsService.saveLastSelectedChannel(newCount);
        _updateFrameDataStructure();
      });
    }
  }

  // ============ FRAME MANAGEMENT METHODS ============

  void _addFrame() {
    setState(() {
      _animationLength++;
      _delayData = _delayData.padRight(_animationLength, '4');
      _frameData.add('0' * (_channelCount * 2));
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _frameScrollController.animateTo(
          _frameScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _removeFrame(int index) {
    if (_animationLength <= 1) return;
    
    setState(() {
      _animationLength--;
      _delayData = _delayData.substring(0, index) + _delayData.substring(index + 1);
      _frameData.removeAt(index);
      
      if (_currentFrame >= _animationLength) {
        _currentFrame = _animationLength - 1;
      }
    });
  }

  void _duplicateFrame(int index) {
    setState(() {
      _animationLength++;
      _delayData = _delayData.substring(0, index + 1) + 
                  _delayData[index] + 
                  _delayData.substring(index + 1);
      _frameData.insert(index + 1, _frameData[index]);
    });
  }

  void _clearFrame(int index) {
    setState(() {
      _frameData[index] = '0' * (_channelCount * 2);
    });
  }

  // ============ MATRIX EDITOR METHODS ============

  void _toggleLED(int channel, int frameIndex) {
    setState(() {
      final frame = _frameData[frameIndex];
      final ledIndex = channel ~/ 4;
      final bitPosition = (channel % 4) * 2;
      
      if (ledIndex < frame.length ~/ 2) {
        final hexDigitIndex = ledIndex;
        final hexValue = int.parse(frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2), radix: 16);
        
        final newHexValue = hexValue ^ (0x03 << bitPosition);
        final newHexString = newHexValue.toRadixString(16).padLeft(2, '0');
        
        _frameData[frameIndex] = frame.substring(0, hexDigitIndex * 2) + 
                               newHexString + 
                               frame.substring(hexDigitIndex * 2 + 2);
      }
    });
  }

  bool _isLEDOn(int channel, int frameIndex) {
    final frame = _frameData[frameIndex];
    final ledIndex = channel ~/ 4;
    final bitPosition = (channel % 4) * 2;
    
    if (ledIndex < frame.length ~/ 2) {
      final hexDigitIndex = ledIndex;
      final hexValue = int.parse(frame.substring(hexDigitIndex * 2, hexDigitIndex * 2 + 2), radix: 16);
      return (hexValue >> bitPosition) & 0x03 != 0;
    }
    
    return false;
  }

  void _setDelayForFrame(int frameIndex, String delay) {
    setState(() {
      final chars = _delayData.split('');
      chars[frameIndex] = delay;
      _delayData = chars.join();
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

  void _saveAnimation() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Please enter animation name');
      return;
    }

    final animation = AnimationModel(
      name: name,
      channelCount: _channelCount,
      animationLength: _animationLength,
      description: _descController.text.trim(),
      delayData: _delayData,
      frameData: _frameData,
    );

    if (!animation.isValid) {
      _showError('Animation data is not valid');
      return;
    }

    _prefsService.addUserSelectedAnimation(animation);
    widget.onSave?.call(animation);
    _showSuccess('Animation "$name" saved successfully!');
  }

  void _clearAllFrames() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkGrey,
        title: const Text('Clear All Frames', style: TextStyle(color: AppColors.pureWhite)),
        content: const Text('Are you sure you want to clear all animation frames?', style: TextStyle(color: AppColors.pureWhite)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.neonGreen)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _frameData = List.generate(_animationLength, (_) => '0' * (_channelCount * 2));
                _currentFrame = 0;
                _isPlaying = false;
              });
              Navigator.pop(context);
              _showSuccess('All frames cleared');
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.errorRed)),
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
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header dengan controls
                      _buildHeader(),
                      const SizedBox(height: 16),
                      
                      // Animation Preview & Playback Controls
                      _buildAnimationPreview(),
                      const SizedBox(height: 16),
                      
                      // Frame Management
                      _buildFrameManagement(),
                      const SizedBox(height: 16),
                      
                      // Matrix Editor - Flexible height
                      _buildMatrixEditor(),
                      const SizedBox(height: 16),
                      
                      // Bottom Controls
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
                      icon: Icon(Icons.speed, color: AppColors.neonGreen, size: 30),
                      onSelected: _setPlaySpeed,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1000, 
                          child: Text('Slow (1s)', style: TextStyle(color: AppColors.pureWhite))
                        ),
                        PopupMenuItem(
                          value: 500, 
                          child: Text('Medium (500ms)', style: TextStyle(color: AppColors.pureWhite))
                        ),
                        PopupMenuItem(
                          value: 200, 
                          child: Text('Fast (200ms)', style: TextStyle(color: AppColors.pureWhite))
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
                color: isSelected ? AppColors.neonGreen : AppColors.primaryBlack,
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
                        color: isSelected ? AppColors.primaryBlack : AppColors.pureWhite,
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
                              _removeFrame(index);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'duplicate', child: Text('Duplicate', style: TextStyle(color: AppColors.pureWhite))),
                          PopupMenuItem(value: 'clear', child: Text('Clear Frame', style: TextStyle(color: AppColors.pureWhite))),
                          if (_animationLength > 1)
                            PopupMenuItem(value: 'delete', child: Text('Delete Frame', style: TextStyle(color: AppColors.errorRed))),
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
              style: TextStyle(
                color: AppColors.neonGreen,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixEditor() {
  final displayFrame = _isPlaying ? _currentFrame : _currentFrame;
  final gridSize = _calculateOptimalGridSize();
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
                'Frame ${displayFrame + 1} Editor - Perfect X Pattern',
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
                notificationPredicate: (notification) => notification.depth == 1,
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

int _calculateOptimalGridSize() {
  // Untuk X sempurna, kita butuh gridSize yang cukup
  // Minimal untuk menampung semua channel dalam pattern X
  final minSize = (_channelCount / 2).ceil();
  return minSize + 1; // Beri sedikit ruang ekstra
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
  final channelInfo = _getChannelForPerfectX(row, col, gridSize);
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
        boxShadow: isOn ? [
          BoxShadow(
            color: AppColors.neonGreen.withOpacity(0.9),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ] : null,
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

Map<String, dynamic> _getChannelForPerfectX(int row, int col, int gridSize) {
  // Pattern X perfect dengan urutan spiral
  // Untuk 8 channel di grid 4x4:
  // 1        8
  //    2  7
  //    3  6
  // 4        5

  // Untuk memastikan X perfect, kita perlu menentukan semua posisi X terlebih dahulu
  final List<Point> xPoints = [];
  
  // Kumpulkan semua titik di pattern X
  for (int i = 0; i < gridSize; i++) {
    for (int j = 0; j < gridSize; j++) {
      // Pattern X: diagonal utama dan diagonal sekunder
      if (i == j || i + j == gridSize - 1) {
        xPoints.add(Point(i, j));
      }
    }
  }
  
  // Urutkan titik-titik dalam pola spiral X
  xPoints.sort((a, b) {
    // Prioritas: layer terluar dulu
    final aLayer = _calculateLayer(a.x, a.y, gridSize);
    final bLayer = _calculateLayer(b.x, b.y, gridSize);
    
    if (aLayer != bLayer) {
      return aLayer.compareTo(bLayer); // Layer terluar dulu
    }
    
    // Dalam layer yang sama, urutkan berdasarkan quadrant
    final aQuadrant = _getQuadrant(a.x, a.y, gridSize);
    final bQuadrant = _getQuadrant(b.x, b.y, gridSize);
    
    if (aQuadrant != bQuadrant) {
      return aQuadrant.compareTo(bQuadrant);
    }
    
    // Dalam quadrant yang sama, urutkan berdasarkan posisi
    if (aQuadrant == 1) return a.x.compareTo(b.x); // Top-left: atas ke bawah
    if (aQuadrant == 2) return b.x.compareTo(a.x); // Top-right: atas ke bawah  
    if (aQuadrant == 3) return a.x.compareTo(b.x); // Bottom-left: atas ke bawah
    if (aQuadrant == 4) return b.x.compareTo(a.x); // Bottom-right: atas ke bawah
    
    return 0;
  });
  
  final key = '$row,$col';
  for (int i = 0; i < xPoints.length; i++) {
    if (i >= _channelCount) break;
    
    final point = xPoints[i];
    if ('${point.x},${point.y}' == key) {
      return {'channel': i, 'isValid': true};
    }
  }
  
  return {'channel': -1, 'isValid': false};
}

int _calculateLayer(int x, int y, int gridSize) {
  // Hitung layer berdasarkan jarak dari tepi
  final distFromTop = x;
  final distFromBottom = gridSize - 1 - x;
  final distFromLeft = y;
  final distFromRight = gridSize - 1 - y;
  
  return [distFromTop, distFromBottom, distFromLeft, distFromRight].reduce((a, b) => a < b ? a : b);
}

int _getQuadrant(int x, int y, int gridSize) {
  final half = gridSize / 2;
  
  if (x < half && y < half) return 1; // Top-left
  if (x < half && y >= half) return 2; // Top-right
  if (x >= half && y < half) return 3; // Bottom-left
  return 4; // Bottom-right
}


  Widget _buildDelayControl(int frameIndex) {
    final currentDelay = frameIndex < _delayData.length ? _delayData[frameIndex] : '4';
    
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
            items: ['1', '2', '3', '4', '5', '6', '7', '8'].map((delay) {
              return DropdownMenuItem(
                value: delay,
                child: Text('$delay', style: TextStyle(color: AppColors.pureWhite)),
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