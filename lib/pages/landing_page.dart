import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/constants/app_colors.dart';
import 'package:ninexmano_matrix/routes/routes.dart';
import 'package:ninexmano_matrix/services/firebase_data_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final FirebaseDataService _firebaseService = FirebaseDataService();
  bool _isInitializing = false;
  String _initStatus = '';

  @override
  void initState() {
    super.initState();
    _initializeAppData();
  }

  // Function untuk initialize data saat pertama kali masuk
  Future<void> _initializeAppData() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
      _initStatus = 'Menyiapkan aplikasi...';
    });

    try {
      print('🚀 Initializing app data...');
      
      // Initialize Firebase Service
      _firebaseService.initialize();
      
      setState(() {
        _initStatus = 'Memuat data sistem...';
      });

      // 1. Coba ambil SYSTEM data (akan auto save ke preferences)
      try {
        await _firebaseService.getSystemModel();
        print('✅ System data initialized');
        setState(() {
          _initStatus = 'System data loaded';
        });
      } catch (e) {
        print('⚠️ System data initialization failed: $e');
        // Tidak masalah jika gagal, continue saja
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _initStatus = 'Memuat data animasi...';
      });

      // 2. Coba ambil USER animations (akan auto save ke preferences)
      try {
        final animations = await _firebaseService.getUserAnimations();
        print('✅ User animations initialized: ${animations.length} animations');
        setState(() {
          _initStatus = '${animations.length} animations loaded';
        });
      } catch (e) {
        print('⚠️ User animations initialization failed: $e');
        // Tidak masalah jika gagal, continue saja
      }

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _initStatus = 'Aplikasi siap!';
      });

      print('🎉 App data initialization completed');
      
      // Tunggu sebentar lalu clear status
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initStatus = '';
        });
      }

    } catch (e) {
      print('❌ App initialization error: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initStatus = 'Aplikasi siap (mode offline)';
        });
      }
      
      // Clear status setelah beberapa detik
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _initStatus = '';
          });
        }
      });
    }
  }

  // Function untuk force refresh data
  Future<void> _forceRefreshData() async {
    setState(() {
      _isInitializing = true;
      _initStatus = 'Memuat ulang data...';
    });

    try {
      // Clear cache dulu
      await _firebaseService.clearCache();
      
      // Fetch data baru
      await _firebaseService.getSystemModel();
      await _firebaseService.getUserAnimations();
      
      setState(() {
        _initStatus = 'Data diperbarui!';
      });
      
      // Clear status setelah beberapa detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _initStatus = '';
          });
        }
      });
      
    } catch (e) {
      print('❌ Force refresh failed: $e');
      setState(() {
        _isInitializing = false;
        _initStatus = 'Gagal memuat data';
      });
      
      // Clear status setelah beberapa detik
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _initStatus = '';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: SafeArea(
        child: Stack(
          children: [
            // Background dengan efek gradient dan pattern
            _buildBackground(),
            
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Tulisan NINE X Mano dengan animasi
                    _buildLogoSection(),
                    
                    const SizedBox(height: 40),
                    
                    // Status initialization
                    if (_initStatus.isNotEmpty) _buildInitStatus(),
                    
                    const SizedBox(height: 20),
                    
                    // Container untuk kedua tombol dengan efek modern
                    _buildButtonSection(context),
                    
                    const SizedBox(height: 40),
                    
                    // Footer text
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (_isInitializing) _buildLoadingOverlay(),
          ],
        ),
      ),

      // Floating button untuk refresh data
      floatingActionButton: _buildRefreshButton(),
    );
  }

  Widget _buildInitStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isInitializing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neonGreen,
              ),
            )
          else
            Icon(
              Icons.check_circle,
              color: AppColors.neonGreen,
              size: 16,
            ),
          const SizedBox(width: 8),
          Text(
            _initStatus,
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.neonGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'Menyiapkan aplikasi...',
              style: TextStyle(
                color: AppColors.pureWhite,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return FloatingActionButton(
      onPressed: _isInitializing ? null : _forceRefreshData,
      backgroundColor: AppColors.neonGreen,
      foregroundColor: AppColors.primaryBlack,
      mini: true,
      child: const Icon(Icons.refresh),
    );
  }

  Widget _buildBackground() {
    return Container(
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
      child: CustomPaint(
        painter: _BackgroundPatternPainter(),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Glow effect untuk NINE
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.neonGreen.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Text(
            'NINE',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: AppColors.neonGreen,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: AppColors.neonGreen,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // X dengan efek modern
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.neonGreen.withOpacity(0.1),
                AppColors.neonGreen.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.neonGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: const Text(
            'X',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w700,
              color: AppColors.pureWhite,
              letterSpacing: 2,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // MANO dengan style yang konsisten
        const Text(
          'MANO',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.pureWhite,
            letterSpacing: 2,
            shadows: [
              Shadow(
                blurRadius: 5,
                color: Colors.black,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Subtitle
        Text(
          'LED MATRIX CONTROLLER',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.pureWhite.withOpacity(0.7),
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildButtonSection(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkGrey.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tombol NORMAL dengan efek hover
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isInitializing 
                      ? null 
                      : () {
                          Navigator.pushNamed(context, AppRoutes.databaseViewer);
                          print('Tombol Normal ditekan');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.primaryBlack,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppColors.neonGreen.withOpacity(0.6),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'NORMAL',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol SHOW dengan style outlined modern
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isInitializing
                      ? null
                      : () {
                          Navigator.pushNamed(context, AppRoutes.dashboard);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.neonGreen,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: AppColors.neonGreen,
                        width: 2,
                      ),
                    ),
                    elevation: 4,
                    shadowColor: AppColors.neonGreen.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dashboard, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SHOW',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'CONTROL YOUR LED MATRIX',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.pureWhite.withOpacity(0.5),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'v1.0.0',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.neonGreen.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// Custom painter untuk background pattern
class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonGreen.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Grid pattern
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner accents
    final cornerPaint = Paint()
      ..color = AppColors.neonGreen.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const cornerSize = 60.0;
    const cornerOffset = 20.0;

    // Top Left
    canvas.drawLine(
      const Offset(cornerOffset, cornerOffset),
      const Offset(cornerOffset + cornerSize, cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(cornerOffset, cornerOffset),
      const Offset(cornerOffset, cornerOffset + cornerSize),
      cornerPaint,
    );

    // Top Right
    canvas.drawLine(
      Offset(size.width - cornerOffset, cornerOffset),
      Offset(size.width - cornerOffset - cornerSize, cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerOffset, cornerOffset),
      Offset(size.width - cornerOffset, cornerOffset + cornerSize),
      cornerPaint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(cornerOffset, size.height - cornerOffset),
      Offset(cornerOffset + cornerSize, size.height - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cornerOffset, size.height - cornerOffset),
      Offset(cornerOffset, size.height - cornerOffset - cornerSize),
      cornerPaint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - cornerOffset, size.height - cornerOffset),
      Offset(size.width - cornerOffset - cornerSize, size.height - cornerOffset),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width - cornerOffset, size.height - cornerOffset),
      Offset(size.width - cornerOffset, size.height - cornerOffset - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}