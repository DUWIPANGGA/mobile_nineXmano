import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/routes/routes.dart';
import 'package:iTen/services/connectivity_service.dart';
import 'package:iTen/services/firebase_data_service.dart';
import 'package:iTen/services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Initializing app...');
  
  try {
    // Initialize services secara berurutan
    await PreferencesService().initialize();
    print('✅ PreferencesService initialized');
    
    // Initialize connectivity service
    ConnectivityService();
    print('✅ ConnectivityService initialized');
    
    // Initialize Firebase service
    FirebaseDataService().initialize();
    print('✅ FirebaseDataService initialized');

    // Test koneksi (optional)
    final hasConnection = await FirebaseDataService().testConnection();
    print(hasConnection ? '🌐 Online mode' : '📂 Offline mode');

  } catch (e) {
    print('❌ Failed to initialize services: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NINE X Mano',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AppColors.neonGreen,
          onPrimary: AppColors.primaryBlack,
          surface: AppColors.darkGrey,
          background: AppColors.primaryBlack,
          onSurface: AppColors.pureWhite,
          onBackground: AppColors.pureWhite,
        ),
        scaffoldBackgroundColor: AppColors.primaryBlack,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkGrey,
          foregroundColor: AppColors.neonGreen,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}