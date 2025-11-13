// map_editor_modal.dart
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/config_service.dart';
import 'package:iTen/services/matrix_pattern_service.dart';
import 'package:iTen/services/socket_service.dart';

class MapEditorModal extends StatefulWidget {
  final String triggerLabel;
  final SocketService socketService;
  final Function(List<int>) onMapDataCreated;
  final List<int>? initialMapData;
  final ConfigModel? configData; // Parameter untuk config dari luar

  const MapEditorModal({
    super.key,
    required this.triggerLabel,
    required this.socketService,
    required this.onMapDataCreated,
    this.initialMapData,
    this.configData, // Config dari TriggerPage
  });

  static void show({
    required BuildContext context,
    required String triggerLabel,
    required SocketService socketService,
    List<int>? initialMapData,
    ConfigModel? configData, // Tambahkan parameter configData
    required Function(List<int>) onMapDataCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MapEditorModal(
        triggerLabel: triggerLabel,
        socketService: socketService,
        initialMapData: initialMapData,
        configData: configData, // Kirim configData ke modal
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
  bool _isInitialized = false;
  ConfigModel? _deviceConfig;

  @override
  void initState() {
    super.initState();
    _initializeFromExternalConfig();
    _channelController.addListener(_onChannelCountChanged);
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  // Method baru: Initialize dari config external
  void _initializeFromExternalConfig() {
    print('🗺️ Initializing MAP Editor from external config...');
    
    // Prioritaskan config dari parameter widget
    if (widget.configData != null) {
      print('📥 Received external config data');
      _deviceConfig = widget.configData;
      _initializeFromConfigModel();
    } 
    // Fallback ke initialMapData jika ada
    else if (widget.initialMapData != null && widget.initialMapData!.isNotEmpty) {
      print('📥 Using initial map data: ${widget.initialMapData}');
      _parseDeviceMapData(widget.initialMapData!);
    } 
    // Final fallback ke default
    else {
      _loadDefaultChannelCount();
    }
    
    _channelController.text = _channelCount.toString();
    _isInitialized = true;
  }

  // Method baru: Initialize dari ConfigModel
  // Di dalam _MapEditorModalState - perbaiki method _initializeFromConfigModel
void _initializeFromConfigModel() {
  if (_deviceConfig == null) return;

  try {
    print('🔧 Initializing from ConfigModel:');
    print('   - Channel Count: ${_deviceConfig!.jumlahChannel}');
    print('   - Trigger Label: ${widget.triggerLabel}');

    // Set channel count dari config
    final configChannelCount = _deviceConfig!.jumlahChannel;
    if (configChannelCount > 0 && configChannelCount <= 80) {
      _channelCount = configChannelCount;
    }

    // PERBAIKAN: Mapping trigger label yang benar
    List<int> triggerData = [];
    switch (widget.triggerLabel) {
      case 'LOW BEAM':
        triggerData = _deviceConfig!.trigger1Data;
        print('   - Using Trigger1 Data for LOW BEAM: ${_deviceConfig!.trigger1Data}');
        break;
      case 'HIGH BEAM':
        triggerData = _deviceConfig!.trigger2Data; // PERBAIKAN: dari trigger2Data
        print('   - Using Trigger2 Data for HIGH BEAM: ${_deviceConfig!.trigger2Data}');
        break;
      case 'FOG LAMP':
        triggerData = _deviceConfig!.trigger3Data; // PERBAIKAN: dari trigger3Data
        print('   - Using Trigger3 Data for FOG LAMP: ${_deviceConfig!.trigger3Data}');
        break;
      default:
        print('⚠️ Unknown trigger label: ${widget.triggerLabel}');
        triggerData = List.filled(10, 0);
    }

    // Debug: Print semua trigger data untuk verifikasi
    print('🔍 All Trigger Data for verification:');
    print('   - Trigger1 (LOW BEAM): ${_deviceConfig!.trigger1Data}');
    print('   - Trigger2 (HIGH BEAM): ${_deviceConfig!.trigger2Data}');
    print('   - Trigger3 (FOG LAMP): ${_deviceConfig!.trigger3Data}');

    // Parse trigger data ke LED states
    if (triggerData.isNotEmpty) {
      _parseTriggerDataFromConfig(triggerData);
    } else {
      _updateLEDStates(); // Fallback ke semua LED mati
    }

    print('✅ Successfully initialized from external config');
    
  } catch (e) {
    print('❌ Error initializing from config: $e');
    _loadDefaultChannelCount();
  }
}

  // Method baru: Parse trigger data dari ConfigModel
  void _parseTriggerDataFromConfig(List<int> triggerData) {
    try {
      print('🔍 Parsing trigger data from config: $triggerData');
      
      // Asumsi: triggerData berisi 10 frame data
      if (triggerData.length >= 10) {
        final frameData = triggerData.sublist(0, 10);
        print('🎯 Frame data: $frameData');
        print('🔢 Channel count: $_channelCount');
        
        _convertMapDataToLEDStates(frameData);
      } else {
        print('⚠️ Trigger data too short, expected 10, got ${triggerData.length}');
        _updateLEDStates();
      }
    } catch (e) {
      print('❌ Error parsing trigger data: $e');
      _updateLEDStates();
    }
  }

  void _parseDeviceMapData(List<int> deviceData) {
    try {
      print('🔍 Parsing device map data: $deviceData');
      
      if (deviceData.length >= 10) {
        // Gunakan channel count dari config jika ada, otherwise dari data
        final deviceChannelCount = _deviceConfig?.jumlahChannel ?? 8;
        if (deviceChannelCount >= 1 && deviceChannelCount <= 80) {
          _channelCount = deviceChannelCount;
        }
        
        final frameData = deviceData.sublist(0, 10);
        print('🎯 Frame data: $frameData');
        print('🔢 Channel count: $_channelCount');
        
        _convertMapDataToLEDStates(frameData);
      } else {
        _loadDefaultChannelCount();
        print('⚠️ Device data format invalid, using default');
      }
    } catch (e) {
      print('❌ Error parsing device map data: $e');
      _loadDefaultChannelCount();
    }
  }

  void _convertMapDataToLEDStates(List<int> frameData) {
    try {
      List<bool> newLEDStates = List.filled(_channelCount, false);
      int currentLED = 0;
      
      for (int frameIndex = 0; frameIndex < frameData.length; frameIndex++) {
        final byteValue = frameData[frameIndex];
        
        for (int bit = 0; bit < 8; bit++) {
          if (currentLED < _channelCount) {
            final isLEDOn = (byteValue & (1 << bit)) != 0;
            newLEDStates[currentLED] = isLEDOn;
            currentLED++;
          }
        }
        
        if (currentLED >= _channelCount) break;
      }
      
      setState(() {
        _ledStates = newLEDStates;
      });
      
      print('💡 Converted map data to LED states:');
      print('   - Active LEDs: ${newLEDStates.where((state) => state).length}');
      print('   - Total LEDs: $_channelCount');
      
    } catch (e) {
      print('❌ Error converting map data to LED states: $e');
      _updateLEDStates();
    }
  }

  void _loadDefaultChannelCount() {
    final configChannelCount = _configService.channelCount;
    if (configChannelCount > 0 && configChannelCount <= 80) {
      _channelCount = configChannelCount;
    }
    _updateLEDStates();
  }

  void _onChannelCountChanged() {
    if (!_isInitialized) return;
    
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
      if (_channelCount < _ledStates.length) {
        _ledStates = _ledStates.sublist(0, _channelCount);
      } else {
        final newLEDStates = List<bool>.from(_ledStates);
        while (newLEDStates.length < _channelCount) {
          newLEDStates.add(false);
        }
        _ledStates = newLEDStates;
      }
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
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neonGreen.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MAP Editor - ${widget.triggerLabel}',
                              style: TextStyle(
                                color: AppColors.neonGreen,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                          ],
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
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

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
                              'CONFIG',
                              style: TextStyle(
                                color: AppColors.neonGreen.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                            Icon(
                              widget.configData != null ? Icons.check_circle : Icons.sync_problem,
                              color: widget.configData != null ? AppColors.neonGreen : AppColors.errorRed,
                              size: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: Container(
                        width: double.infinity,
  alignment: Alignment.center, 

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

                  
                  const SizedBox(height: 12),

                  SafeArea(
                    top: false,
                    child: Row(
                      children: [
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

  String _getPreviewData() {
    final mapData = _convertLEDStatesToMapData();
    final paddedData = _padMapDataTo10Frames(mapData);
    
    final result = [...paddedData, int.parse(_channelController.text)];
    
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
      
      final mappingCode = _getMappingCode(widget.triggerLabel);
      widget.socketService.sendMappingData(mappingCode, paddedData, int.parse(_channelController.text));
      
      widget.onMapDataCreated([...paddedData, int.parse(_channelController.text)]);
      
      _showSnackbar(
        'Data MAP berhasil dikirim! '
        '(${paddedData.length} frame + channel $_channelController)'
      );
      
      print('🗺️ Sent MAP data for ${widget.triggerLabel}:');
      print('   - Frames: $paddedData');
      print('   - Channel: $_channelController');
      print('   - Code: $mappingCode');

      Navigator.pop(context);

    } catch (e) {
      _showSnackbar('Error mengirim data MAP: $e', isError: true);
      print('❌ Error sending MAP data: $e');
    }
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

  List<int> _padMapDataTo10Frames(List<int> frameData) {
    final List<int> padded = List<int>.from(frameData);
    
    while (padded.length < 10) {
      padded.add(0);
    }
    
    if (padded.length > 10) {
      padded.removeRange(10, padded.length);
    }
    
    return padded;
  }

  String _getMappingCode(String triggerLabel) {
    switch (triggerLabel) {
      case 'LOW BEAM':
        return 'DL';
      case 'HIGH BEAM':
        return 'DH';
      case 'FOG LAMP':
        return 'DF';
      default:
        return 'DM';
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