import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/services/socket_service.dart';

class ControlPage extends StatefulWidget {
  final SocketService socketService;

  const ControlPage({super.key, required this.socketService});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // State variables
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _showModeActive = false;
  bool _testModeEnabled = false;
  int _speedRun = 50;
  String _currentAnimation = '-';
  
  List<String> _logMessages = [];
  final TextEditingController _speedController = TextEditingController();

  // Stream subscriptions
  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _speedController.text = _speedRun.toString();
    _setupSocketListeners();
    if (widget.socketService.isConnected) {
        debugPrint("✅ Connected, sending XM10");
        widget.socketService.send("XM10");
      } 
    widget.socketService.onConnectionChanged = (isConnected) {
      if (isConnected) {
        debugPrint("✅ Connected, sending XM10");
        widget.socketService.send("XM10");
      } else {
        debugPrint("❌ Disconnected");
      }
    };
        // widget.socketService.send("XM10");
  }

  void _setupSocketListeners() {
    _messageSubscription = widget.socketService.messages.listen((message) {
      _handleSocketMessage(message);
    });

    _connectionSubscription = widget.socketService.connectionStatus.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isConnecting = false;
        });
      }
    });
  }

  void _handleSocketMessage(String message) {
    print('ControlPage received: $message');
    _addLogMessage('📥: $message');

    if (message.startsWith('config2,')) {
      _handleConfigShowResponse(message);
    } else if (message.startsWith('info,')) {
      final infoMessage = message.substring(5);
      _showSnackbar(infoMessage);
      _addLogMessage('💡: $infoMessage');
    } else if (message.startsWith('CONFIG_UPDATED:')) {
      _addLogMessage('🔄 Config updated');
    }
  }

  void _handleConfigShowResponse(String message) {
    final parts = message.split(',');
    if (parts.length >= 6) {
      setState(() {
        _showModeActive = true;
        _speedRun = int.tryParse(parts[2]) ?? 50;
        _speedController.text = _speedRun.toString();
      });
      _addLogMessage('✅ Mode Show aktif - Firmware: ${parts[1]}');
    }
  }

  // ========== CONNECTION METHODS ==========

  Future<void> _connectToDevice() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
    });

    await widget.socketService.connect();

    if (widget.socketService.isConnected) {
      widget.socketService.requestConfig();
    }
  }

  void _disconnectFromDevice() {
    widget.socketService.disconnect();
    setState(() {
      _isConnected = false;
      _isConnecting = false;
    });
  }

  Widget _buildConnectionButton() {
    if (_isConnecting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warningYellow.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.warningYellow),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warningYellow,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Connecting...',
              style: TextStyle(
                color: AppColors.warningYellow,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_isConnected) {
      return GestureDetector(
        onTap: () => _showConnectionMenu(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.successGreen),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Connected',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more,
                size: 12,
                color: AppColors.successGreen,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _connectToDevice,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.errorRed),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 12, color: AppColors.errorRed),
            const SizedBox(width: 6),
            Text(
              'Connect',
              style: TextStyle(
                color: AppColors.errorRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== SHOW CONTROL METHODS ==========

  void _enterShowMode() {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    widget.socketService.send('XC');
    _addLogMessage('🎭 Memasuki Mano Show Mode...');
  }

  void _startShow() {
    if (!_showModeActive) {
      _showSnackbar('Masuk ke Show Mode terlebih dahulu');
      return;
    }

    widget.socketService.remoteShow('A');
    setState(() {
      _currentAnimation = '1';
    });
    _addLogMessage('▶️ Memulai show - Animasi 1');
  }

  void _stopShow() {
    widget.socketService.remoteShow('Z');
    setState(() {
      _currentAnimation = '-';
    });
    _addLogMessage('⏹️ Menghentikan show');
  }

  void _nextAnimation() {
    if (!_showModeActive) return;
    
    // Logic untuk next animation
    final current = int.tryParse(_currentAnimation) ?? 1;
    final next = current < 13 ? current + 1 : 1;
    
    final command = String.fromCharCode(64 + next);
    widget.socketService.remoteShow(command);
    
    setState(() {
      _currentAnimation = next.toString();
    });
    _addLogMessage('⏭️ Animasi $next');
  }

  void _previousAnimation() {
    if (!_showModeActive) return;
    
    final current = int.tryParse(_currentAnimation) ?? 1;
    final previous = current > 1 ? current - 1 : 13;
    
    final command = String.fromCharCode(64 + previous);
    widget.socketService.remoteShow(command);
    
    setState(() {
      _currentAnimation = previous.toString();
    });
    _addLogMessage('⏮️ Animasi $previous');
  }

  void _toggleTestMode() {
    setState(() {
      _testModeEnabled = !_testModeEnabled;
    });
    
    widget.socketService.setTestModeShow(_testModeEnabled);
    _addLogMessage(_testModeEnabled ? '🔴 Test Mode ON' : '🟢 Test Mode OFF');
  }

  void _updateSpeedRun() {
    final speed = int.tryParse(_speedController.text) ?? 50;
    if (speed >= 10 && speed <= 1000) {
      setState(() => _speedRun = speed);
      widget.socketService.setSpeedRun(speed);
      _addLogMessage('⚡ Speed run diupdate: $speed ms');
    } else {
      _showSnackbar('Speed harus antara 10-1000 ms');
    }
  }

  void _controlShowAnimation(int animationNumber) {
    if (!_showModeActive) return;

    final command = String.fromCharCode(64 + animationNumber);
    widget.socketService.remoteShow(command);
    
    setState(() {
      _currentAnimation = animationNumber.toString();
    });
    _addLogMessage('🎛️ Animasi $animationNumber');
  }

  void _sendRemoteCommand(String command) {
    if (!widget.socketService.isConnected) {
      _showSnackbar('Tidak terhubung ke device');
      return;
    }

    if (command == 'Z') {
      // Tombol Auto - kirim XRZ
      widget.socketService.send('XRZ');
      setState(() {
        _currentAnimation = 'Auto';
      });
      _addLogMessage('🔄 Auto mode diaktifkan');
    } else {
      // Tombol 1-13 - kirim XRA sampai XRM
      final remoteCommand = 'XR${String.fromCharCode(64 + int.parse(command))}';
      widget.socketService.send(remoteCommand);
      
      setState(() {
        _currentAnimation = command;
      });
      _addLogMessage('🎛️ Remote command: $remoteCommand');
    }
  }

  // ========== UI BUILDERS ==========

  Widget _buildStatusSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Connection Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'STATUS',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildConnectionButton(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Status Indicators
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStatusIndicator(
                  'Connection',
                  _isConnected ? 'Connected' : 'Disconnected',
                  _isConnected ? AppColors.successGreen : AppColors.errorRed,
                ),
                _buildStatusIndicator(
                  'Show Mode',
                  _showModeActive ? 'Active' : 'Inactive',
                  _showModeActive ? AppColors.successGreen : AppColors.errorRed,
                ),
                _buildStatusIndicator(
                  'Test Mode',
                  _testModeEnabled ? 'ON' : 'OFF',
                  _testModeEnabled ? AppColors.warningYellow : AppColors.successGreen,
                ),
                _buildStatusIndicator(
                  'Current Anim',
                  _currentAnimation,
                  AppColors.neonGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.pureWhite.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowControlSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SHOW CONTROL',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Speed Control
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _speedController,
                    decoration: const InputDecoration(
                      labelText: 'Speed Run (ms)',
                      labelStyle: TextStyle(color: AppColors.pureWhite),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.neonGreen),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.pureWhite),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSmallButton('UPDATE', _updateSpeedRun),
              ],
            ),
            const SizedBox(height: 16),
            
            // Control Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildControlButton(
                  _showModeActive ? 'STOP SHOW' : 'START SHOW',
                  _showModeActive ? _stopShow : _enterShowMode,
                  icon: _showModeActive ? Icons.stop : Icons.play_arrow,
                ),
                _buildControlButton(
                  'TEST MODE',
                  _toggleTestMode,
                  icon: Icons.build,
                ),
                if (_showModeActive) ...[
                  _buildControlButton(
                    'START ANIM 1',
                    () => _controlShowAnimation(1),
                    icon: Icons.play_arrow,
                  ),
                  _buildControlButton(
                    'NEXT',
                    _nextAnimation,
                    icon: Icons.skip_next,
                  ),
                  _buildControlButton(
                    'PREV',
                    _previousAnimation,
                    icon: Icons.skip_previous,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(String text, VoidCallback onPressed, {IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonGreen,
        foregroundColor: AppColors.primaryBlack,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox(),
      label: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRemoteControlSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REMOTE CONTROL',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kontrol manual animasi:',
              style: TextStyle(color: AppColors.pureWhite, fontSize: 12),
            ),
            const SizedBox(height: 16),
            
            // Grid untuk tombol remote
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: 14, // 1 auto + 13 tombol biasa
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Tombol Auto
                  return _buildRemoteButton(
                    'AUTO',
                    onPressed: () => _sendRemoteCommand('Z'),
                    isAuto: true,
                  );
                } else {
                  // Tombol 1-13
                  final buttonNumber = index;
                  return _buildRemoteButton(
                    buttonNumber.toString(),
                    onPressed: () => _sendRemoteCommand(buttonNumber.toString()),
                    isActive: _currentAnimation == buttonNumber.toString(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemoteButton(String label, {VoidCallback? onPressed, bool isAuto = false, bool isActive = false}) {
    Color backgroundColor = isAuto ? AppColors.warningYellow : AppColors.neonGreen;
    if (isActive) {
      backgroundColor = AppColors.successGreen;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppColors.primaryBlack,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuickAnimationsSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'QUICK ANIMATIONS',
              style: TextStyle(
                color: AppColors.neonGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAnimButton('Rainbow', 'RH03'),
                _buildQuickAnimButton('Sparkle', 'RH05'),
                _buildQuickAnimButton('Wave', 'RH07'),
                _buildQuickAnimButton('Fire', 'RH09'),
                _buildQuickAnimButton('Strobe', 'RH11'),
                _buildQuickAnimButton('Fade', 'RH13'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAnimButton(String label, String command) {
    return ElevatedButton(
      onPressed: () {
        if (!widget.socketService.isConnected) {
          _showSnackbar('Tidak terhubung ke device');
          return;
        }
        widget.socketService.send(command);
        _addLogMessage('🌈 Quick Animation: $label');
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlack,
        foregroundColor: AppColors.neonGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.neonGreen),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLogSection() {
    return Card(
      color: AppColors.darkGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CONTROL LOG',
                  style: TextStyle(
                    color: AppColors.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildSmallButton('CLEAR', () {
                  setState(() => _logMessages.clear());
                }),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlack,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
              ),
              child: _logMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada log messages',
                        style: TextStyle(color: AppColors.pureWhite),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _logMessages.length,
                      itemBuilder: (context, index) {
                        final message = _logMessages.reversed.toList()[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            message,
                            style: TextStyle(
                              color: AppColors.pureWhite.withOpacity(0.8),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(String text, VoidCallback onPressed) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.neonGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showConnectionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connection Menu',
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isConnected ? AppColors.successGreen : AppColors.errorRed,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isConnected ? AppColors.successGreen : AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isConnected 
                            ? 'Connected to Device' 
                            : 'Disconnected',
                        style: TextStyle(
                          color: _isConnected ? AppColors.successGreen : AppColors.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (_isConnected) ...[
                _buildConnectionAction(
                  icon: Icons.refresh,
                  title: 'Reconnect',
                  onTap: _connectToDevice,
                ),
                _buildConnectionAction(
                  icon: Icons.settings,
                  title: 'Request Config',
                  onTap: () {
                    widget.socketService.requestConfig();
                    Navigator.pop(context);
                    _showSnackbar('Requesting device config...');
                  },
                ),
                _buildConnectionAction(
                  icon: Icons.wifi_off,
                  title: 'Disconnect',
                  onTap: () {
                    _disconnectFromDevice();
                    Navigator.pop(context);
                  },
                  isDestructive: true,
                ),
              ] 
              // else [
              //   _buildConnectionAction(
              //     icon: Icons.wifi,
              //     title: 'Connect to Device',
              //     onTap: () {
              //       _connectToDevice();
              //       Navigator.pop(context);
              //     },
              //   ),
              // ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectionAction({
    required IconData icon,
    required String title,
    required Function() onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.errorRed : AppColors.neonGreen,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.errorRed : AppColors.pureWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }

  void _addLogMessage(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final logMessage = '[$timestamp] $message';
    
    setState(() {
      _logMessages.add(logMessage);
      if (_logMessages.length > 50) {
        _logMessages.removeAt(0);
      }
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          message,
          style: TextStyle(color: AppColors.primaryBlack),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // _buildStatusSection(),
            // const SizedBox(height: 16),
            // _buildShowControlSection(),
            const SizedBox(height: 16),
            _buildRemoteControlSection(),
            const SizedBox(height: 16),
            // _buildQuickAnimationsSection(),
            // const SizedBox(height: 16),
            // _buildLogSection(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _speedController.dispose();
    super.dispose();
  }
}