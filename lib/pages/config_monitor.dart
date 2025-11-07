// widgets/config_monitor_widget.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/models/config_model.dart';
import 'package:ninexmano_matrix/services/config_service.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class ConfigMonitorWidget extends StatefulWidget {
  final SocketService socketService;
  
  const ConfigMonitorWidget({
    super.key,
    required this.socketService,
  });

  @override
  State<ConfigMonitorWidget> createState() => _ConfigMonitorWidgetState();
}

class _ConfigMonitorWidgetState extends State<ConfigMonitorWidget> {
  final ConfigService _configService = ConfigService();
  String _configStatus = 'Unknown';
  String _lastUpdate = 'Never';
  bool _isConnected = false;
  ConfigModel? _config;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _loadConfigStatus();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen untuk connection status
    widget.socketService.connectionStatus.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
    });

    // Listen untuk config updates
    widget.socketService.messages.listen((message) {
      if (message.startsWith('CONFIG_UPDATED')) {
        setState(() {
          _configStatus = 'Received & Saved';
          _lastUpdate = DateTime.now().toString().split('.')[0];
        });
        
        // Reload config details
        _loadConfigStatus();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Config updated successfully!'),
            backgroundColor: Colors.green,
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
          ),
        );
      }
    });
  }

  Future<void> _loadConfigStatus() async {
    try {
      final stats = await _configService.getConfigStats();
      _config = await _configService.loadConfig();
      
      setState(() {
        _configStatus = stats['hasConfig'] ? 'Saved in Storage' : 'Not Received';
        if (stats['hasConfig']) {
          _configStatus += ' (${stats['firmware']})';
        }
      });
      
      // Print semua data ke console untuk debug
      _printAllConfigData();
      
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
    print('   - Password: ${_config!.password.isNotEmpty ? "***${_config!.password.substring(_config!.password.length - 3)}" : "Empty"}');
    
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

  Future<void> _requestConfig() async {
    if (!widget.socketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not connected to device'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _configStatus = 'Requesting...';
    });

    widget.socketService.requestConfig();
    
    // Tunggu maksimal 5 detik
    await Future.delayed(const Duration(seconds: 5));
    _loadConfigStatus();
  }

  Future<void> _clearConfig() async {
    await _configService.clearConfig();
    setState(() {
      _config = null;
      _configStatus = 'Cleared';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Config cleared from storage'),
        backgroundColor: Colors.blue,
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
            // Header
            const Text(
              'Configuration Monitor',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Monitor and debug device configuration data',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildStatusRow('Connection', _isConnected ? '✅ Connected' : '❌ Disconnected'),
                    _buildStatusRow('Config Status', _configStatus),
                    _buildStatusRow('Last Update', _lastUpdate),
                    _buildStatusRow('Config Valid', _config?.isValid.toString() ?? 'Unknown'),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _requestConfig,
                            child: const Text('Request Config'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _loadConfigStatus,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text('Refresh Status'),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearConfig,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('Clear Config'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _showDetails = !_showDetails;
                              });
                            },
                            child: Text(_showDetails ? 'Hide Details' : 'Show Details'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Detailed Config Data
            if (_showDetails && _config != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detailed Configuration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      
                      _buildConfigSection('Basic Info', [
                        _buildDetailRow('Firmware', _config!.firmware),
                        _buildDetailRow('MAC Address', _config!.mac),
                        _buildDetailRow('License Type', _config!.typeLicense.toString()),
                        _buildDetailRow('Channels', _config!.jumlahChannel.toString()),
                        _buildDetailRow('Email', _config!.email),
                        _buildDetailRow('SSID', _config!.ssid),
                        _buildDetailRow('Password', _config!.password.isNotEmpty ? '••••••••' : 'Empty'),
                      ]),
                      
                      _buildConfigSection('Timing Settings', [
                        _buildDetailRow('Delay 1', '${_config!.delay1}ms'),
                        _buildDetailRow('Delay 2', '${_config!.delay2}ms'),
                        _buildDetailRow('Delay 3', '${_config!.delay3}ms'),
                        _buildDetailRow('Delay 4', '${_config!.delay4}ms'),
                      ]),
                      
                      _buildConfigSection('Animation Selections', [
                        _buildDetailRow('Selection 1', _config!.selection1.toString()),
                        _buildDetailRow('Selection 2', _config!.selection2.toString()),
                        _buildDetailRow('Selection 3', _config!.selection3.toString()),
                        _buildDetailRow('Selection 4', _config!.selection4.toString()),
                      ]),
                      
                      _buildConfigSection('Device Info', [
                        _buildDetailRow('Device ID', _config!.devID),
                        _buildDetailRow('Mitra ID', _config!.mitraID),
                        _buildDetailRow('Welcome Anim', _config!.animWelcome.toString()),
                        _buildDetailRow('Welcome Duration', '${_config!.durasiWelcome}s'),
                      ]),
                      
                      _buildConfigSection('Trigger Settings', [
                        _buildDetailRow('Trigger 1 Mode', _config!.trigger1Mode.toString()),
                        _buildDetailRow('Trigger 2 Mode', _config!.trigger2Mode.toString()),
                        _buildDetailRow('Trigger 3 Mode', _config!.trigger3Mode.toString()),
                        _buildDetailRow('Quick Trigger', _config!.quickTrigger.toString()),
                      ]),
                    ],
                  ),
                ),
              ),
              
              // Raw Data Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raw Data Preview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'First 200 characters of stored data:',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _config.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontFamily: 'Monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_showDetails && _config == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.info, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'No configuration data available',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Request configuration from device first',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value.contains('✅') ? Colors.green : 
                       value.contains('❌') ? Colors.red : 
                       value == 'true' ? Colors.green :
                       value == 'false' ? Colors.red : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}