// map_editor_modal.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/config_service.dart';
import 'package:ninexmano_matrix/services/matrix_pattern_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

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
                  // Channel Count Input
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
                          'JUMLAH CHANNEL',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Input Number
                            Expanded(
                              child: TextField(
                                controller: _channelController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: AppColors.pureWhite,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.neonGreen,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: AppColors.neonGreen,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
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
                            ),
                            const SizedBox(width: 12),
                            // Quick Buttons
                            Column(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () => _setChannelCount(16),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _channelCount == 16
                                          ? AppColors.neonGreen
                                          : AppColors.darkGrey,
                                      foregroundColor: _channelCount == 16
                                          ? AppColors.primaryBlack
                                          : AppColors.neonGreen,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: BorderSide(
                                          color: AppColors.neonGreen,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '16',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 60,
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () => _setChannelCount(80),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _channelCount == 80
                                          ? AppColors.neonGreen
                                          : AppColors.darkGrey,
                                      foregroundColor: _channelCount == 80
                                          ? AppColors.primaryBlack
                                          : AppColors.neonGreen,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        side: BorderSide(
                                          color: AppColors.neonGreen,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '80',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Range: 1-80 channels | Grid: ${gridSize}x$gridSize',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info
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
                          child: Text(
                            'Tap LED untuk menyalakan/mematikan. Grid akan menyesuaikan jumlah channel.',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 12,
                            ),
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
                              'GRID SIZE',
                              style: TextStyle(
                                color: AppColors.neonGreen.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${gridSize}x$gridSize',
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

                        // Tombol Kirim ke Device
                        Expanded(
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
        width: 30,
        height: 30,
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
        width: 30,
        height: 30,
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
                    blurRadius: 8,
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
              fontSize: 8,
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

  void _sendToDevice() {
    final mapData = _convertLEDStatesToMapData();
    widget.onMapDataCreated(mapData);
    Navigator.pop(context);
  }

  List<int> _convertLEDStatesToMapData() {
    List<int> result = [];
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
}
