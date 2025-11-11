// providers/config_provider.dart
import 'package:flutter/material.dart';
import 'package:iTen/models/config_model.dart';
import 'package:iTen/services/config_service.dart';

class ConfigProvider with ChangeNotifier {
  final ConfigService _configService = ConfigService();
  ConfigModel? _config;

  ConfigModel? get config => _config;
  bool get hasConfig => _config != null && _config!.isValid;
  int? get channelCount => _config?.jumlahChannel;

  Future<void> initialize() async {
    await _configService.initialize();

    // Listen to config changes
    _configService.configStream.listen((newConfig) {
      _config = newConfig;
      notifyListeners();
    });
  }

  Future<void> clearConfig() async {
    await _configService.clearConfig();
    _config = null;
    notifyListeners();
  }
}
