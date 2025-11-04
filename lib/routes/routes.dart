// routes/routes.dart
import 'package:flutter/material.dart';
import 'package:ninexmano_matrix/pages/cloud_file_page.dart';
import 'package:ninexmano_matrix/pages/dashboard_page.dart';
import 'package:ninexmano_matrix/pages/database_viewer_page.dart'; // ADD THIS
import 'package:ninexmano_matrix/pages/landing_page.dart';
import 'package:ninexmano_matrix/pages/mapping_page.dart';
import 'package:ninexmano_matrix/pages/my_file_page.dart';
import 'package:ninexmano_matrix/pages/remote_page.dart';
import 'package:ninexmano_matrix/pages/settings_page.dart';
import 'package:ninexmano_matrix/pages/trigger_page.dart';

class AppRoutes {
  static const String landing = '/';
  static const String dashboard = '/dashboard';
  static const String remote = '/remote';
  static const String mapping = '/mapping';
  static const String trigger = '/trigger';
  static const String myFile = '/my-file';
  static const String cloudFile = '/cloud-file';
  static const String settings = '/settings';
  static const String databaseViewer = '/database-viewer'; // ADD THIS

  static final Map<String, WidgetBuilder> routes = {
    landing: (context) => const LandingPage(),
    dashboard: (context) => const DashboardPage(),
    remote: (context) => const RemotePage(),
    mapping: (context) => const MappingPage(),
    trigger: (context) => const TriggerPage(),
    myFile: (context) => const MyFilePage(),
    cloudFile: (context) => const CloudFilePage(),
    settings: (context) => const SettingsPage(),
    databaseViewer: (context) => const DatabaseViewerPage(), // ADD THIS
  };
}