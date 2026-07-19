import 'package:flutter/material.dart';
import 'tenant_settings_service.dart';

class RunsService extends ChangeNotifier {
  final TenantSettingsService _settings;

  RunsService(this._settings) {
    _settings.addListener(notifyListeners);
  }

  int get count => _settings.runCount;

  String getName(int i) => _settings.getRunName(i);

  List<String> get names => List.generate(count, getName);

  void setCount(int v) => _settings.setRunCount(v);

  void setName(int i, String name) => _settings.setRunName(i, name);

  @override
  void dispose() {
    _settings.removeListener(notifyListeners);
    super.dispose();
  }
}
