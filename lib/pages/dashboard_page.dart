import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/constants/app_config.dart';
import 'package:iTen/pages/config_monitor.dart';
import 'package:iTen/pages/editor_page.dart';
import 'package:iTen/pages/mapping_page.dart';
import 'package:iTen/pages/my_file_page.dart';
import 'package:iTen/pages/remote_page.dart';
import 'package:iTen/pages/settings_page.dart';
import 'package:iTen/pages/trigger_page.dart';
import 'package:iTen/services/socket_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  late SocketService _socketService;
  bool _isConnecting = false;
  bool _isConnected = false;

  // Pages akan di-initialize di initState dengan shared socketService
  late final List<Widget> _pages;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Remote', 'icon': Icons.gamepad, 'color': AppColors.neonGreen},
    {'title': 'Mapping', 'icon': Icons.map, 'color': AppColors.neonGreen},
    {'title': 'Editor', 'icon': Icons.edit, 'color': AppColors.neonGreen},
    {'title': 'Trigger', 'icon': Icons.play_arrow, 'color': AppColors.neonGreen},
    {'title': 'My File', 'icon': Icons.folder, 'color': AppColors.neonGreen},
    {'title': 'Setting', 'icon': Icons.settings, 'color': AppColors.neonGreen},
    // {'title': 'Monitor', 'icon': Icons.monitor, 'color': AppColors.neonGreen},
  ];

  @override
  void initState() {
    super.initState();
  _socketService = SocketService();
    _socketService.addConsumer();
    _initializePages();
    _setupSocketListeners();
    
  }

  void _initializePages() {
    _pages = [
      RemotePage(socketService: _socketService),
      MappingPage(socketService: _socketService),
      EditorPage(),
      TriggerPage(socketService: _socketService),
      MyFilePage(),
      SettingsPage(socketService: _socketService),
      // ConfigMonitorWidget(socketService: _socketService)
      // Tambahkan page untuk Setting atau gunakan placeholder
      // _buildPlaceholderPage('Settings Page'), // Placeholder untuk Setting
    ];
  }

  // Placeholder untuk page yang belum ada
  
  void _setupSocketListeners() {
    _socketService.connectionStatus.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isConnecting = false;
        });
      }
    });

    _socketService.messages.listen((message) {
      print('Dashboard received: $message');
    });
  }

  Future<void> _connectToDevice() async {
    if (_isConnecting || _isConnected) return;

    setState(() {
      _isConnecting = true;
    });

    await _socketService.connect();

    if (_socketService.isConnected) {
      _socketService.requestConfig();
    }
  }

  void _disconnectFromDevice() {
    _socketService.disconnect();
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
        onTap: _disconnectFromDevice,
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
              
              // Connection Status
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
              
              // Connection Actions
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
                    _socketService.requestConfig();
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
              ] else ...[
                _buildConnectionAction(
                  icon: Icons.wifi,
                  title: 'Connect to Device',
                  onTap: () {
                    _connectToDevice();
                    Navigator.pop(context);
                  },
                ),
              ],
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neonGreen,
        content: Text(
          message,
          style: TextStyle(
            color: AppColors.primaryBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          // Header dengan logo NINE X MANO dan connection button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 40,bottom: 20, right: 20,left: 20),
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.neonGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Logo dari asset
    SizedBox(
      width: 100, // Sesuaikan ukuran sesuai kebutuhan
      height: 40,  // Sesuaikan ukuran sesuai kebutuhan
      child: Image.asset(
        AppConfig.logoApp,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback jika gambar tidak ditemukan
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'NINE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.neonGreen,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'X MANO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pureWhite,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        },
      ),
    ),

    // Current Page Title dengan validasi index
    Text(
      _getCurrentPageTitle(),
      style: const TextStyle(
        color: AppColors.pureWhite,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Connection Status Button dengan menu
    GestureDetector(
      onTap: () => _showConnectionMenu(context),
      child: _buildConnectionButton(),
    ),
  ],
),
          ),

          // Shortcut Menu dengan design modern
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.darkGrey,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                for (int i = 0; i < _menuItems.length; i++)
                  _buildShortcut(
                    _menuItems[i]['title'],
                    _menuItems[i]['icon'],
                    i,
                  ),
              ],
            ),
          ),

          // Content Area dengan validasi index
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    AppColors.darkGrey.withOpacity(0.8),
                    AppColors.primaryBlack,
                  ],
                ),
              ),
              child: _getCurrentPage(),
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk mendapatkan current page dengan validasi
  Widget _getCurrentPage() {
    if (_currentIndex >= 0 && _currentIndex < _pages.length) {
      return _pages[_currentIndex];
    } else {
      // Fallback ke page pertama jika index invalid
      return _pages[0];
    }
  }

  // Method untuk mendapatkan current page title dengan validasi
  String _getCurrentPageTitle() {
    if (_currentIndex >= 0 && _currentIndex < _menuItems.length) {
      return _menuItems[_currentIndex]['title'];
    } else {
      return _menuItems[0]['title']; // Fallback ke title pertama
    }
  }

  Widget _buildShortcut(String title, IconData icon, int index) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.neonGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: AppColors.neonGreen,
            width: isActive ? 0 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.neonGreen.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primaryBlack : AppColors.neonGreen,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primaryBlack : AppColors.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
_socketService.removeConsumer();
    super.dispose();
  }
}