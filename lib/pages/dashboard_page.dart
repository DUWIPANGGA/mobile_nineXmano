import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/pages/cloud_file_page.dart';
import 'package:ninexmano_matrix/pages/mapping_page.dart';
import 'package:ninexmano_matrix/pages/my_file_page.dart';
import 'package:ninexmano_matrix/pages/remote_page.dart';
import 'package:ninexmano_matrix/pages/settings_page.dart';
import 'package:ninexmano_matrix/pages/trigger_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RemotePage(),
    const MappingPage(),
    Container(color: AppColors.darkGrey, child: const Center(child: Text('Editor Page', style: TextStyle(color: AppColors.pureWhite)))),
    const TriggerPage(),
    const MyFilePage(),
    const CloudFilePage(),
    const SettingsPage(),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Remote', 'icon': Icons.gamepad, 'color': AppColors.neonGreen},
    {'title': 'Mapping', 'icon': Icons.map, 'color': AppColors.neonGreen},
    {'title': 'Editor', 'icon': Icons.edit, 'color': AppColors.neonGreen},
    {'title': 'Trigger', 'icon': Icons.play_arrow, 'color': AppColors.neonGreen},
    {'title': 'My File', 'icon': Icons.folder, 'color': AppColors.neonGreen},
    {'title': 'Cloud File', 'icon': Icons.cloud, 'color': AppColors.neonGreen},
    {'title': 'Setting', 'icon': Icons.settings, 'color': AppColors.neonGreen},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Column(
        children: [
          // Header dengan logo NINE X MANO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                // Logo
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
                
                // Current Page Title
                Text(
                  _menuItems[_currentIndex]['title'],
                  style: const TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Placeholder untuk balance layout
                const SizedBox(width: 60),
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
          
          // Content Area
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
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
    );
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
}