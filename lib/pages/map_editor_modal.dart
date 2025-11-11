// map_editor_modal.dart
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/services/config_service.dart';
import 'package:iTen/services/matrix_pattern_service.dart';
import 'package:iTen/services/socket_service.dart';

class MapEditorModal extends StatefulWidget {
  final String triggerLabel;
  final SocketService socketService;
  final Function(List<int>) onMapDataCreated;

  const MapEditorModal({
    super.key,
    required this.triggerLabel,
    required this.socketService,
    required this.onMapDataCreated,
  });

  // Method untuk show modal
  static void show({
    required BuildContext context,
    required String triggerLabel,
    required SocketService socketService,
    required Function(List<int>) onMapDataCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapEditorModal(
        triggerLabel: triggerLabel,
        socketService: socketService,
        onMapDataCreated: onMapDataCreated,
      ),
    );
  }

  @override
  State<MapEditorModal> createState() => _MapEditorModalState();
}

class _MapEditorModalState extends State<MapEditorModal> {
  final MatrixPatternService _patternService = MatrixPatternService();
  final ConfigService _configService = ConfigService();
  int _channelCount = 80;
  List<bool> _ledStates = List.filled(80, false);
  final TextEditingController _channelController = TextEditingController();
  int _selectedChannel = 1; // Default channel 1

  @override
  void initState() {
    super.initState();
    _loadDefaultChannelCount();
    _channelController.text = _channelCount.toString();
    _channelController.addListener(_onChannelCountChanged);
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  void _loadDefaultChannelCount() {
    final configChannelCount = _configService.channelCount;
    if (configChannelCount > 0 && configChannelCount <= 80) {
      _channelCount = configChannelCount;
    }
    _updateLEDStates();
  }

  void _onChannelCountChanged() {
    final text = _channelController.text;
    if (text.isNotEmpty) {
      final newCount = int.tryParse(text) ?? _channelCount;
      if (newCount >= 1 && newCount <= 80) {
        setState(() {
          _channelCount = newCount;
          _updateLEDStates();
        });
      }
    }
  }

  void _updateLEDStates() {
    setState(() {
      _ledStates = List.filled(_channelCount, false);
    });
  }

  void _setChannelCount(int count) {
    if (count >= 1 && count <= 80) {
      setState(() {
        _channelCount = count;
        _channelController.text = count.toString();
        _updateLEDStates();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = _patternService.calculateOptimalGridSize(_channelCount);
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;

    return Container(
      height: mediaQuery.size.height * 0.9,
      margin: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: AppColors.neonGreen, width: 2),
      ),
      child: Column(
        children: [
          // Header dengan drag handle
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                // Title dan Close Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MAP Editor - ${widget.triggerLabel}',
                        style: TextStyle(
                          color: AppColors.neonGreen,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: AppColors.neonGreen),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 24,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Channel Configuration
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.neonGreen.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KONFIGURASI CHANNEL',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Baris untuk jumlah channel
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'JUMLAH CHANNEL',
                                    style: TextStyle(
                                      color: AppColors.pureWhite.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _channelController,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color: AppColors.pureWhite,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppColors.neonGreen,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppColors.neonGreen,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: BorderSide(
                                          color: AppColors.neonGreen,
                                        ),
                                      ),
                                      hintText: '1-80',
                                      hintStyle: TextStyle(
                                        color: AppColors.pureWhite.withOpacity(0.5),
                                      ),
                                      counterText: '',
                                    ),
                                    maxLength: 2,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 12),
                            
                            // Channel selection untuk mapping
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'CHANNEL MAP',
                                    style: TextStyle(
                                      color: AppColors.pureWhite.withOpacity(0.8),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: AppColors.neonGreen),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: DropdownButton<int>(
                                      value: _selectedChannel,
                                      isExpanded: true,
                                      dropdownColor: AppColors.darkGrey,
                                      style: TextStyle(
                                        color: AppColors.pureWhite,
                                        fontSize: 14,
                                      ),
                                      underline: const SizedBox(),
                                      icon: Icon(
                                        Icons.arrow_drop_down,
                                        color: AppColors.neonGreen,
                                      ),
                                      items: List.generate(16, (index) => index + 1)
                                          .map((channel) {
                                        return DropdownMenuItem<int>(
                                          value: channel,
                                          child: Text(
                                            'Channel $channel',
                                            style: TextStyle(
                                              color: AppColors.pureWhite,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedChannel = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Quick channel buttons
                        Row(
                          children: [
                            _buildQuickChannelButton(16),
                            const SizedBox(width: 8),
                            _buildQuickChannelButton(32),
                            const SizedBox(width: 8),
                            _buildQuickChannelButton(64),
                            const SizedBox(width: 8),
                            _buildQuickChannelButton(80),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        Text(
                          'Grid: ${gridSize}x$gridSize | Map Channel: $_selectedChannel',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info Panel
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.darkGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: AppColors.neonGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data akan dikirim sebagai 11 values:',
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '10 frame values + 1 channel value',
                                style: TextStyle(
                                  color: AppColors.neonGreen,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Frame yang kosong akan diisi 0',
                                style: TextStyle(
                                  color: AppColors.pureWhite.withOpacity(0.8),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Status Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.neonGreen.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'CHANNELS',
                              style: TextStyle(
                                color: AppColors.neonGreen.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '$_channelCount',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'ACTIVE LEDS',
                              style: TextStyle(
                                color: AppColors.neonGreen.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${_ledStates.where((state) => state).length}',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              'MAP CHANNEL',
                              style: TextStyle(
                                color: AppColors.neonGreen.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '$_selectedChannel',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Grid LED
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkGrey,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: _buildPerfectXGrid(gridSize),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Preview Data
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.neonGreen),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIEW DATA (11 VALUES):',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getPreviewData(),
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 10,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Controls
                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // Tombol Clear All
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _clearAllLEDs,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.errorRed,
                              side: BorderSide(color: AppColors.errorRed),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.clear, size: 18),
                            label: Text('CLEAR ALL'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Tombol Pattern
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _fillPattern,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.neonGreen,
                              side: BorderSide(color: AppColors.neonGreen),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.pattern, size: 18),
                            label: Text('PATTERN'),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Tombol Kirim ke Device
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _sendToDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.neonGreen,
                              foregroundColor: AppColors.primaryBlack,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: Icon(Icons.send, size: 18),
                            label: Text('KIRIM KE DEVICE'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChannelButton(int count) {
    return Expanded(
      child: SizedBox(
        height: 30,
        child: ElevatedButton(
          onPressed: () => _setChannelCount(count),
          style: ElevatedButton.styleFrom(
            backgroundColor: _channelCount == count
                ? AppColors.neonGreen
                : AppColors.darkGrey,
            foregroundColor: _channelCount == count
                ? AppColors.primaryBlack
                : AppColors.neonGreen,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: AppColors.neonGreen),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerfectXGrid(int gridSize) {
    return Column(
      children: [
        for (int row = 0; row < gridSize; row++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int col = 0; col < gridSize; col++)
                _buildPerfectXLED(row, col, gridSize),
            ],
          ),
      ],
    );
  }

  Widget _buildPerfectXLED(int row, int col, int gridSize) {
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
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: AppColors.darkGrey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final isOn = channel < _ledStates.length ? _ledStates[channel] : false;
    final displayNumber = channel + 1;

    return GestureDetector(
      onTap: () => _toggleLED(channel),
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: isOn ? AppColors.neonGreen : AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.neonGreen.withOpacity(0.8),
            width: 1,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$displayNumber',
            style: TextStyle(
              color: isOn ? AppColors.primaryBlack : AppColors.pureWhite,
              fontSize: 7,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLED(int channel) {
    if (channel < _ledStates.length) {
      setState(() {
        _ledStates[channel] = !_ledStates[channel];
      });
    }
  }

  void _clearAllLEDs() {
    setState(() {
      _ledStates = List.filled(_channelCount, false);
    });
  }

  void _fillPattern() {
    setState(() {
      // Fill dengan pattern checkerboard
      for (int i = 0; i < _ledStates.length; i++) {
        _ledStates[i] = (i % 2 == 0);
      }
    });
  }

  String _getPreviewData() {
    final mapData = _convertLEDStatesToMapData();
    final paddedData = _padMapDataTo10Frames(mapData);
    
    // Format: [frame1, frame2, ..., frame10, channel]
    final result = [...paddedData, _selectedChannel];
    
    return result.map((v) => v.toString().padLeft(3)).join(' ');
  }

  void _sendToDevice() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Harap connect ke device terlebih dahulu!', isError: true);
      return;
    }

    try {
      final mapData = _convertLEDStatesToMapData();
      final paddedData = _padMapDataTo10Frames(mapData);
      
      // Kirim menggunakan socket service
      final mappingCode = _getMappingCode(widget.triggerLabel);
      widget.socketService.sendMappingData(mappingCode, paddedData, _selectedChannel);
      
      // Panggil callback
      widget.onMapDataCreated([...paddedData, _selectedChannel]);
      
      _showSnackbar(
        'Data MAP berhasil dikirim! '
        '(${paddedData.length} frame + channel $_selectedChannel)'
      );
      
      print('🗺️ Sent MAP data for ${widget.triggerLabel}:');
      print('   - Frames: $paddedData');
      print('   - Channel: $_selectedChannel');
      print('   - Code: $mappingCode');

      Navigator.pop(context);

    } catch (e) {
      _showSnackbar('Error mengirim data MAP: $e', isError: true);
      print('❌ Error sending MAP data: $e');
    }
  }

  List<int> _convertLEDStatesToMapData() {
    List<int> result = [];
    
    // Convert LED states ke bytes (8 LED per byte)
    for (int i = 0; i < _channelCount; i += 8) {
      int byteValue = 0;
      for (int j = 0; j < 8; j++) {
        final ledIndex = i + j;
        if (ledIndex < _channelCount && _ledStates[ledIndex]) {
          byteValue |= (1 << j);
        }
      }
      result.add(byteValue);
    }
    
    return result;
  }

  List<int> _padMapDataTo10Frames(List<int> frameData) {
    final List<int> padded = List<int>.from(frameData);
    
    // Pad dengan 0 jika kurang dari 10 frame
    while (padded.length < 10) {
      padded.add(0);
    }
    
    // Pastikan tidak lebih dari 10 frame
    if (padded.length > 10) {
      padded.removeRange(10, padded.length);
    }
    
    return padded;
  }

  String _getMappingCode(String triggerLabel) {
    switch (triggerLabel) {
      case 'LOW BEAM':
        return 'DL'; // Data Low Beam Mapping
      case 'HIGH BEAM':
        return 'DH'; // Data High Beam Mapping
      case 'FOG LAMP':
        return 'DF'; // Data Fog Lamp Mapping
      default:
        return 'DM'; // Default Mapping
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
}