// widgets/config_monitor_widget.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/config_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class ConfigMonitorWidget extends StatefulWidget {
  final SocketService socketService;

  const ConfigMonitorWidget({super.key, required this.socketService});

  @override
  State<ConfigMonitorWidget> createState() => _ConfigMonitorWidgetState();
}

class _ConfigMonitorWidgetState extends State<ConfigMonitorWidget> {
  final ConfigService _configService = ConfigService();
  String _configStatus = 'Loading...';
  String _lastUpdate = 'Never';
  bool _isConnected = false;
  ConfigModel? _config;
  bool _showDetails = false;
  String _dataSource = 'from local';

  @override
  void initState() {
    super.initState();
    _loadConfigFromPreferences();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    widget.socketService.connectionStatus.listen((connected) {
      setState(() {
        _isConnected = connected;
        if (connected) {
          _dataSource = 'from device';
        } else {
          _dataSource = 'from local';
        }
      });
    });

    widget.socketService.messages.listen((message) {
      if (message.startsWith('CONFIG_UPDATED')) {
        setState(() {
          _configStatus = 'Received & Saved';
          _lastUpdate = _formatDateTime(DateTime.now());
          _dataSource = 'from device';
        });

        _loadConfigFromPreferences();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Config updated from device!'),
            backgroundColor: AppColors.neonGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else if (message.startsWith('CONFIG_ERROR')) {
        setState(() {
          _configStatus = 'Error: ${message.substring(12)}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Config error: ${message.substring(12)}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadConfigFromPreferences() async {
    try {
      setState(() {
        _configStatus = 'Loading from storage...';
      });

      _config = await _configService.currentConfig;

      if (_config != null) {
        setState(() {
          _configStatus = 'Loaded from storage';
          _lastUpdate = _formatDateTime(DateTime.now());
        });
        _printAllConfigData();
      } else {
        setState(() {
          _configStatus = 'No config data found';
          _lastUpdate = 'Never';
        });
      }
    } catch (e) {
      setState(() {
        _configStatus = 'Error: $e';
      });
    }
  }

  void _printAllConfigData() {
    print('🔍 === ALL CONFIG DATA FROM STORAGE ===');

    if (_config == null) {
      print('❌ No config data found in storage');
      return;
    }

    print('📋 BASIC INFO:');
    print('   - Firmware: ${_config!.firmware}');
    print('   - MAC: ${_config!.mac}');
    print('   - Type License: ${_config!.typeLicense}');
    print('   - Jumlah Channel: ${_config!.jumlahChannel}');
    print('   - Email: ${_config!.email}');
    print('   - SSID: ${_config!.ssid}');
    print(
      '   - Password: ${_config!.password.isNotEmpty ? "***${_config!.password.substring(_config!.password.length - 3)}" : "Empty"}',
    );

    print('⏱️ DELAY SETTINGS:');
    print('   - Delay 1: ${_config!.delay1}ms');
    print('   - Delay 2: ${_config!.delay2}ms');
    print('   - Delay 3: ${_config!.delay3}ms');
    print('   - Delay 4: ${_config!.delay4}ms');

    print('🎯 SELECTION SETTINGS:');
    print('   - Selection 1: ${_config!.selection1}');
    print('   - Selection 2: ${_config!.selection2}');
    print('   - Selection 3: ${_config!.selection3}');
    print('   - Selection 4: ${_config!.selection4}');

    print('🆔 IDENTIFICATION:');
    print('   - Device ID: ${_config!.devID}');
    print('   - Mitra ID: ${_config!.mitraID}');

    print('👋 WELCOME SETTINGS:');
    print('   - Welcome Animation: ${_config!.animWelcome}');
    print('   - Welcome Duration: ${_config!.durasiWelcome}s');

    print('⚡ TRIGGER SETTINGS:');
    print('   - Trigger 1 Data: ${_config!.trigger1Data}');
    print('   - Trigger 2 Data: ${_config!.trigger2Data}');
    print('   - Trigger 3 Data: ${_config!.trigger3Data}');
    print('   - Trigger 1 Mode: ${_config!.trigger1Mode}');
    print('   - Trigger 2 Mode: ${_config!.trigger2Mode}');
    print('   - Trigger 3 Mode: ${_config!.trigger3Mode}');
    print('   - Quick Trigger: ${_config!.quickTrigger}');

    print('✅ VALIDATION:');
    print('   - Config Valid: ${_config!.isValid}');
    print('   - Summary: ${_config!.summary}');

    print('📊 STORAGE INFO:');
    print('   - Last Update: $_lastUpdate');
    print('   - Status: $_configStatus');

    print('🔚 === END CONFIG DATA ===');
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  Future<void> _requestConfig() async {
    if (!widget.socketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Not connected to device'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _configStatus = 'Requesting from device...';
    });

    widget.socketService.requestConfig();

    await Future.delayed(const Duration(seconds: 5));
    _loadConfigFromPreferences();
  }

  Future<void> _clearConfig() async {
    await _configService.clearConfig();
    setState(() {
      _config = null;
      _configStatus = 'Config cleared';
      _lastUpdate = 'Never';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Config cleared from storage'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan styling matrix
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monitor_heart,
                    color: AppColors.neonGreen,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONFIG MONITOR',
                          style: TextStyle(
                            color: AppColors.neonGreen,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Real-time device configuration monitor',
                          style: TextStyle(
                            color: AppColors.pureWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Data Source Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _dataSource == 'from device'
                          ? AppColors.neonGreen.withOpacity(0.15)
                          : Colors.blue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _dataSource == 'from device'
                            ? AppColors.neonGreen
                            : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _dataSource.toUpperCase(),
                      style: TextStyle(
                        color: _dataSource == 'from device'
                            ? AppColors.neonGreen
                            : Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status Card dengan styling modern
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STATUS OVERVIEW',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildStatusRow(
                    'Device Connection',
                    _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                    _isConnected ? AppColors.neonGreen : Colors.red,
                    Icons.link,
                  ),
                  _buildStatusRow(
                    'Config Status',
                    _configStatus,
                    _getStatusColor(_configStatus),
                    Icons.storage,
                  ),
                  _buildStatusRow(
                    'Last Update',
                    _lastUpdate,
                    AppColors.pureWhite.withOpacity(0.7),
                    Icons.access_time,
                  ),
                  _buildStatusRow(
                    'Config Valid',
                    _config?.isValid.toString() ?? '-',
                    _config?.isValid == true
                        ? AppColors.neonGreen
                        : _config?.isValid == false
                            ? Colors.red
                            : Colors.grey,
                    Icons.verified,
                  ),

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.neonGreen.withOpacity(0.9),
                                AppColors.neonGreen.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.neonGreen.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _requestConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.primaryBlack,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.download, size: 18),
                            label: const Text(
                              'REQUEST CONFIG',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlack,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.neonGreen.withOpacity(0.5),
                            ),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _loadConfigFromPreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.neonGreen,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text(
                              'REFRESH',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _clearConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.red,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.delete, size: 16),
                            label: const Text(
                              'CLEAR CONFIG',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.neonGreen.withOpacity(0.5),
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showDetails = !_showDetails;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.neonGreen,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              _showDetails ? 'HIDE DETAILS' : 'SHOW DETAILS',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Detailed Config Data
            if (_showDetails) ...[
              if (_config != null) ...[
                _buildConfigSection(
                  'BASIC INFORMATION',
                  Icons.info,
                  [
                    _buildDetailRow('Firmware', _config!.firmware),
                    _buildDetailRow('MAC Address', _config!.mac),
                    _buildDetailRow(
                      'License Type',
                      _config!.typeLicense.toString(),
                    ),
                    _buildDetailRow(
                      'Channels',
                      '${_config!.jumlahChannel} channels',
                    ),
                    _buildDetailRow('Email', _config!.email),
                    _buildDetailRow('SSID', _config!.ssid),
                    _buildDetailRow(
                      'Password',
                      _config!.password.isNotEmpty ? '••••••••' : 'Empty',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildConfigSection(
                  'TIMING SETTINGS',
                  Icons.timer,
                  [
                    _buildDetailRow('Delay 1', '${_config!.delay1}ms'),
                    _buildDetailRow('Delay 2', '${_config!.delay2}ms'),
                    _buildDetailRow('Delay 3', '${_config!.delay3}ms'),
                    _buildDetailRow('Delay 4', '${_config!.delay4}ms'),
                  ],
                ),

                const SizedBox(height: 16),

                _buildConfigSection(
                  'ANIMATION SELECTIONS',
                  Icons.animation,
                  [
                    _buildDetailRow('Selection 1', _config!.selection1.toString()),
                    _buildDetailRow('Selection 2', _config!.selection2.toString()),
                    _buildDetailRow('Selection 3', _config!.selection3.toString()),
                    _buildDetailRow('Selection 4', _config!.selection4.toString()),
                  ],
                ),

                const SizedBox(height: 16),

                _buildConfigSection(
                  'DEVICE INFORMATION',
                  Icons.device_hub,
                  [
                    _buildDetailRow('Device ID', _config!.devID),
                    _buildDetailRow('Mitra ID', _config!.mitraID),
                    _buildDetailRow(
                      'Welcome Animation',
                      _config!.animWelcome.toString(),
                    ),
                    _buildDetailRow(
                      'Welcome Duration',
                      '${_config!.durasiWelcome}s',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildConfigSection(
                  'TRIGGER SETTINGS',
                  Icons.flash_on,
                  [
                    _buildDetailRow('Trigger 1 Mode', _config!.trigger1Mode.toString()),
                    _buildDetailRow('Trigger 2 Mode', _config!.trigger2Mode.toString()),
                    _buildDetailRow('Trigger 3 Mode', _config!.trigger3Mode.toString()),
                    _buildDetailRow('Quick Trigger', _config!.quickTrigger.toString()),
                  ],
                ),

                const SizedBox(height: 20),

                // Raw Data Preview
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.code, color: AppColors.neonGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'RAW DATA PREVIEW',
                            style: TextStyle(
                              color: AppColors.neonGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlack,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.neonGreen.withOpacity(0.2),
                          ),
                        ),
                        child: SelectableText(
                          _config.toString().length > 200
                              ? '${_config.toString().substring(0, 200)}...'
                              : _config.toString(),
                          style: TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 10,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No Data State
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox,
                        color: AppColors.neonGreen.withOpacity(0.5),
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Configuration Data',
                        style: TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Request configuration from device or check if data exists in storage',
                        style: TextStyle(
                          color: AppColors.pureWhite.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.pureWhite.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.neonGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.neonGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neonGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.pureWhite.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Loaded') || status.contains('Saved')) {
      return AppColors.neonGreen;
    } else if (status.contains('Error') || status.contains('No config')) {
      return Colors.red;
    } else if (status.contains('Requesting') || status.contains('Loading')) {
      return Colors.orange;
    } else {
      return AppColors.pureWhite;
    }
  }
}