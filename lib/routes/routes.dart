// routes/routes.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/pages/cloud_file_page.dart';
import 'package:ninexmano_matrix/pages/config_monitor.dart';
import 'package:ninexmano_matrix/pages/dashboard_page.dart';
import 'package:ninexmano_matrix/pages/database_viewer_page.dart';
import 'package:ninexmano_matrix/pages/editor_page.dart';
import 'package:ninexmano_matrix/pages/landing_page.dart';
import 'package:ninexmano_matrix/pages/mapping_page.dart';
import 'package:ninexmano_matrix/pages/my_file_page.dart';
import 'package:ninexmano_matrix/pages/remote_page.dart';
import 'package:ninexmano_matrix/pages/settings_page.dart';
import 'package:ninexmano_matrix/pages/sysc_page.dart';
import 'package:ninexmano_matrix/pages/trigger_page.dart';
import 'package:ninexmano_matrix/services/socket_service.dart';

class AppRoutes {
  static const String landing = '/';
  static const String dashboard = '/dashboard';
  static const String remote = '/remote';
  static const String mapping = '/mapping';
  static const String trigger = '/trigger';
  static const String myFile = '/my-file';
  static const String cloudFile = '/cloud-file';
  static const String settings = '/settings';
  static const String editor = '/editor';
  static const String databaseViewer = '/database-viewer';
  static const String monitor = '/config-monitor';
  static const String sync = '/sync'; // ROUTE BARU

  static final Map<String, WidgetBuilder> routes = {
    landing: (context) => const LandingPage(),
    dashboard: (context) => const DashboardPage(),
    editor: (context) => const EditorPage(),
    remote: (context) => RemotePage(socketService: SocketService()),
    mapping: (context) => MappingPage(socketService: SocketService()),
    trigger: (context) => TriggerPage(socketService: SocketService()),
    myFile: (context) => const MyFilePage(),
    cloudFile: (context) => const CloudFilePage(),
    settings: (context) => SettingsPage(socketService: SocketService()),
    databaseViewer: (context) => const DatabaseViewerPage(),
    monitor: (context) => ConfigMonitorWidget(socketService: SocketService()),
    sync: (context) => SyncPage(socketService: SocketService()), // PAGE BARU
  };

  // Helper method untuk navigasi
  static void navigateTo(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  // Navigasi dengan menghapus stack sebelumnya
  static void navigateReplacement(BuildContext context, String routeName) {
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  // Navigasi dengan menghapus semua stack
  static void navigateAndRemoveUntil(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName, 
      (route) => false
    );
  }

  // Method khusus untuk navigasi ke SyncPage dengan data tambahan (jika perlu)
  static void navigateToSyncPage(BuildContext context, {bool? isMaster}) {
    Navigator.of(context).pushNamed(
      sync,
      // arguments: {'isMaster': isMaster} // Jika perlu pass data
    );
  }
}