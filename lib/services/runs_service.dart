import 'package:flutter/material.dart';
import 'prefs_service.dart';

class RunsService extends ChangeNotifier {
  int get count => PrefsService.runCount;

  String getName(int i) => PrefsService.getRunName(i);

  List<String> get names => List.generate(count, (i) => getName(i));

  void setCount(int v) {
    PrefsService.runCount = v;
    notifyListeners();
  }

  void setName(int i, String name) {
    PrefsService.setRunName(i, name);
    notifyListeners();
  }
}
