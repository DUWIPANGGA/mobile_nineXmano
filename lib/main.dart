import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iTen/constants/app_colors.dart';
import 'package:iTen/routes/routes.dart';
import 'package:iTen/services/firebase_data_service.dart';

import 'firebase_options.dart';

void main() async {
    WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
    FirebaseDataService().initialize(); // ADD THIS

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




